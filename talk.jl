using HTTP
using Sockets, .Threads

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
end

const peers = Dict() # { TCPSocket : Peer }


#

const string_delimiter = "run<>fox<>run"
const byte_delimiter = Vector{UInt8}(string_delimiter)

const max_bytes = 2056 # todo: implement this  # Todo: all "read" parts require this

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


function handshake_peer_to_me(peer::TCPSocket)
	try

		peer_publickey = i_want_publickey(peer)
		if peer_publickey==false
			close(peer)
			return
		end

		they_want_publickey(peer)

		symkey = i_want_symkey(peer)

		peer_id = hashi(peer_publickey)
		peers[peer] = Peer(Node(peer_id, peer_ip, peer_port, now(), now()), symkey, peer_publickey)

	catch e
		println("handshake_peer2me with: $peer error: $e")
		close(peer)
	end
end

function handshake_me_to_peer(peer_ip::String, peer_port::Int)
	try

		peer = connect(peer_ip, peer_port)

		they_want_publickey(peer)

		peer_publickey = i_want_publickey(peer)
		if peer_publickey==false
			close(peer)
			return
		end

		symkey = they_want_symkey(peer)

		peer_id = hashi(peer_publickey)
		peers[peer] = Peer(Node(peer_id, peer_ip, peer_port, now(), now()), symkey, peer_publickey)

	catch e
		println("handshake_me2peer with: $peer error: $e")
		close(peer)
	end
end


#


function payload_peer_to_me(peer::TCPSocket, secure=false)
	payload = UInt8[]
    while true
        push!(payload, read(peer, UInt8))
        if length(payload) >= length(byte_delimiter) && payload[end-length(byte_delimiter)+1:end] == byte_delimiter
            resize!(payload, length(payload)-length(byte_delimiter))
            break
        end
    end
    if secure payload = decrypt_sk(payload, peers[peer].symkey.split(string_delimiter)...) end
    return buffer
end

function payload_me_to_peer(peer::TCPSocket, payload::Vector{UInt8}, secure=false)
	if secure payload = encrypt_sk(payload, peers[peer].symkey.split(string_delimiter)...) end
	write(peer, payload)
	write(peer, byte_delimiter)
end


function message_peer_to_me(peer::TCPSocket, secure=false)
	message = readline(peer)
	if secure message = decrypt_sk(message, peers[peer].symkey.split(string_delimiter)...) end
	return message
end

function message_me_to_peer(peer::TCPSocket, message::String, secure=false)
	if secure message = encrypt_sk(message, peers[peer].symkey.split(string_delimiter)...) end
	write(peer, message*"\n")
end


#




# Dont forget --- you can send JSON.stringify(string)   while sending strings - it makes it easier.


function handle_peer(peer::TCPSocket)

	message = readline(peer)

	if message=="hello"
		handshake_peer_to_me(peer)

	elseif message=="ping"
		write(peer, "pong"*"\n")

	elseif message=="find" # node or data , given an id


	elseif message=="node" # given a node_id


	elseif message=="data" # given a data_id OR node_id-data_id  ==> in this case, they need to seek node first..


	elseif message=="store"



	elseif message=="boot"


	end


end















#


function start_server(ip, port)

 	ip_addr = ip isa IPAddr ? ip : ip isa AbstractString ? parse(IPAddr, ip) : error("Invalid IP address format")
    server = listen(ip_addr, port)
    println("Server is running on $ip:$port")

    sock = connect(ip, port)

    while true
        peer_sock = accept(server)
        Threads.@spawn handle_peer(peer_sock)
    end

end

start_server("localhost", port)




function communicate_with_server(ip, port)

    sock = connect(ip, port)

    try

        send_string = "Hello, Server!\n"
        write(sock, send_string)
        println("Sent to peer: $send_string")

        response = readline(sock)
        println("Received from peer: $response")

        byte_packet = UInt8[0x01, 0x02, 0x03, 0x04]
        write(sock, byte_packet)
        write(sock, byte_delimiter)

        final_response = readline(sock)
        println("Final response from server: $final_response")

    catch e
        println("An error occurred: $e")
    finally
        close(sock)
    end

end

communicate_with_server("127.0.0.1", 1234)










# Thrad Pool for new requests instead of 1 for each
# Defining a Protocol: Raw sockets just send streams of bytes without any inherent structure. Define a simple protocol to frame your messages, which might include specifying the length of messages or starting with a specific byte sequence.
# Graceful Error Recovery: Implement robust error handling that can gracefully manage and recover from errors like network failures, disconnections, or corrupted data packets.
# Timeouts and Keep-Alives: Define timeout policies for inactive connections and implement keep-alive messages to maintain connections that are still open but idle.
# Connection Throttling: Implement throttling mechanisms to control the rate of incoming connections and data processing to protect against DoS attacks and ensure service availability.
# Buffer Management: Efficiently manage buffers for sending and receiving data to optimize memory usage and prevent buffer overflows.

# The one who opens the contact first, should send ping/pong (keepalive) requests at each N seconds


# rlock = ReentrantLock()
# lock(rlock)
# unlock(rlock)

# Threads.@threads for i = 1:10
#     result[i] = Threads.threadid()
# end

# Threads.@spawn handle_peer(peer_sock)
