using HTTP
using Sockets
using JSON

include("node.jl")

#

const ip = String(HTTP.get("https://multifox.ai/whoami").body)
const port = 9696

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


const max_bytes = 2056
# todo: implement this  # Todo: all "read" parts require this

const string_delimiter = "run<>fox<>run"
const byte_delimiter = Vector{UInt8}(string_delimiter)


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
	message = readline(peer)
	message = decrypt_pk(message) # I decrypt with my privatekey
	return message
end

function they_want_symkey(peer::TCPSocket)
	symkey, symiv = generate_sk()
	message = symkey*string_delimiter*symiv
	peer_publickey = find_peer_by_server(peer).publickey
	open(peer_publickey*".txt", "w") do file write(file, peer_publickey) end
	message = encrypt_pk(message, peer_publickey*".txt") # I encrypt with their publickey
	rm(peer_publickey*".txt")
	write(peer, message*"\n")
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

	peer = get(peers, peer_id, Nothing) # check if my client has already connected to their server

	if peer==Nothing # first time we connect
		symkey = i_want_symkey(peer_client)
		peers[peer_id] = Peer(Node(peer_id, peer_ip, Nothing, now(UTC), now(UTC)), symkey, peer_publickey, peer_client, Nothing)
	else
		peer.peer_client = peer_client
	end

	return peer_id
end

function i_want_connection(peer_ip::String, peer_port=port) # my client to their server

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

	peer = get(peers, peer_id, Nothing) # check if their client has already connected to my server

	if peer==Nothing # first time we connect
		peers[peer_id] = Peer(Node(peer_id, peer_ip, Nothing, now(UTC), now(UTC)), Nothing, peer_publickey, Nothing, peer_server)
		peers[peer_id].symkey = they_want_symkey(peer_server)
	else
		peer.peer_server = peer_server
		peer.node.port = peer_port
	end

	return peer_id
end


#


function payload_peer_to_me(peer::TCPSocket; secure=true)
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

function payload_me_to_peer(peer::TCPSocket, payload::Vector{UInt8}; secure=true)
	if secure payload = encrypt_sk(payload, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	write(peer, payload)
	write(peer, byte_delimiter)
end


function message_peer_to_me(peer::TCPSocket; json=false, secure=true) # TODO: make sure json.json really jsons the "\n"s correctly.
	message = readline(peer)
	if secure message = decrypt_sk(message, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	if json message = JSON.parse(message) end
	return message
end

function message_me_to_peer(peer::TCPSocket; message::String, json=false, secure=true)
	if json message = JSON.json(message) end
	if secure message = encrypt_sk(message, find_peer_by_socket(peer).symkey.split(string_delimiter)...) end
	write(peer, message*"\n")
end


#
