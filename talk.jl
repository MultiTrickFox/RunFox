using HTTP
using Sockets

include("node.jl")

#

const publickey = !isfile("publickey.txt") ? generate_pk() : read("publickey.txt", String)
const id = hashi(publickey)
println("id is: $id")
const privatekey = read("privatekey.pem")

const ip = String(HTTP.get("https://multifox.ai/whoami").body)
const port = 9696
println("ip is: $ip")

#


struct Peer
	node::Node
	symkey::String
	publickey::String
	client::TCPSocket # client is for you-ask-me
	server::TCPSocket # server is for i-ask-you
end
==(p1::Peer, p2::Peer) = (p1.node == p2.node)

const peers = Dict() # { node_id : Peer }

function find_peer_by_client(client::TCPSocket) for peer in values(peers) if peer.client==client return peer end end end
function find_peer_by_server(server::TCPSocket) for peer in values(peers) if peer.server==server return peer end end end
function find_peer_by_socket(socket::TCPSocket) for peer in values(peers) if peer.server==socket || peer.client==socket return peer end end end


#

const string_delimiter = "run<>fox<>run"
const byte_delimiter = Vector{UInt8}(string_delimiter)

const max_bytes = 2056 # todo: implement this  # Todo: all "read" parts require this


function payload_peer_to_me(peer::TCPSocket, secure=false)
	payload = UInt8[]
    while true
        push!(payload, read(peer, UInt8))
        if length(payload) >= length(byte_delimiter) && payload[end-length(byte_delimiter)+1:end] == byte_delimiter
            resize!(payload, length(payload)-length(byte_delimiter))
            break
        end
    end
    if secure payload = decrypt_sk(payload, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
    return buffer
end

function payload_me_to_peer(peer::TCPSocket, payload::Vector{UInt8}, secure=false)
	if secure payload = encrypt_sk(payload, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	write(peer, payload)
	write(peer, byte_delimiter)
end


function message_peer_to_me(peer::TCPSocket, secure=false)
	message = readline(peer)
	if secure message = decrypt_sk(message, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	return message
end

function message_me_to_peer(peer::TCPSocket, message::String, secure=false)
	if secure message = encrypt_sk(message, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	write(peer, message*"\n")
end


#


function i_want_publickey(peer::TCPSocket)
	peer_publickey = readline(peer) # ask their publickey
	auth_req = hashi(rand(UInt8,16)) # auth with their privatekey
	write(peer, auth_req*"\n")
	auth_res = readline(peer)
    open(peer_publickey*".txt", "w") do file write(file, peer_publickey) end
	auth_success = verify_pk(ip*"<>"*port*"<>"*auth_req, auth_res, peer_publickey*".txt")
	rm(peer_publickey*".txt")
	return auth_success ? peer_publickey : false
end

function they_want_publickey(peer::TCPSocket)
	peer_ip, peer_port = getpeername(peer)
	write(peer, publickey*"\n") # they ask my publickey
	auth_req = readline(peer) # they auth with my privatekey
	write(peer, sign_pk(string(peer_ip)*"<>"*peer_port*"<>"*msg)*"\n")
end


function i_want_symkey(peer::TCPSocket)
	return readline(peer)
end

function they_want_symkey(peer::TCPSocket)
	symkey, symiv = generate_sk()
	write(peer, symkey*string_delimiter*symiv*"\n")
	return symkey*string_delimiter*symiv
end


#


# client: req giver, res taker
# server: req taker, res giver


function they_want_connection(peer_client::TCPSocket) # their client to my server

	peer_ip, peer_port = getpeername(peer_client)

	## We always verify each other's public key

	peer_publickey = i_want_publickey(peer_client)
	if peer_publickey==false
		close(peer_client)
		return
	end

	they_want_publickey(peer_client)

	peer_id = hashi(peer_publickey)

	##

	# check if my client is already connected to their server
	peer = get(peers, peer_id, Nothing)

	if peer==Nothing # first time we connect
		symkey = i_want_symkey(peer_client)
		peers[peer_id] = Peer(Node(peer_id, peer_ip, Nothing, now(), now()), symkey, peer_publickey, peer_client, Nothing)
	else
		peer.peer_client = peer_client
	end

	return peer_id
end

function i_want_connection(peer_ip::String, peer_port::Int) # my client to their server

	peer_server = connect(peer_ip, peer_port)

	## We always verify each other's public key

	they_want_publickey(peer_server)

	peer_publickey = i_want_publickey(peer_server)
	if peer_publickey==false
		close(peer_server)
		return
	end

	peer_id = hashi(peer_publickey)

	##

	# check if their client is already connected to my server
	peer = get(peers, peer_id, Nothing)

	if peer==Nothing # first time we connect
		symkey = they_want_symkey(peer_server)
		peers[peer_id] = Peer(Node(peer_id, peer_ip, Nothing, now(), now()), symkey, peer_publickey, Nothing, peer_server)
	else
		peer.peer_server = peer_server
		peer.node.port = peer_port
	end

	return peer_id
end


#
