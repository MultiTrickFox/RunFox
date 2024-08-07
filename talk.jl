using HTTP
using Sockets, .Threads

include("node.jl")

#

const publickey = !isfile("publickey.txt") ? generate_pk() : read("publickey.txt", String)
const id = hashish(publickey)
println("id is: $id")
const privatekey = read("privatekey.pem")

const ip = String(HTTP.get("https://multifox.ai/whoami").body)
const port = 9696
println("ip is: $ip")


#


struct Contact
	node::Node
	socket::TCPSocket
end

const contact_list = Dict()


#

const byte_delimiter = Vector{UInt8}("run<>fox")

const max_bytes = 2056 # todo: implement this

function readbytes(client)
	buffer = UInt8[]
    while true
        push!(buffer, read(client_socket, UInt8))
        if length(buffer) >= length(byte_delimiter) && buffer[end-length(byte_delimiter)+1:end] == byte_delimiter
            resize!(buffer, length(buffer)-length(byte_delimiter))
            break
        end
    end
    return buffer
end

#



## Handshake protocol
#
# I am the server
# they ask my publickey, I send it
# they want to authenticate me, I sign it and send it
# I ask for their publickey
# I authenticate them
# if everything checks out, I added them as contact, and sent nack
#

# I am the client
# ...




function they_want_connection(client::TCPSocket)
	try

		client_ip, client_port = getpeername(client)

		# ask their publickey
		client_publickey = readline(client)
		client_id = hashish(client_publickey)

		# auth their privatekey
		auth_req = hashish(rand(UInt8,16))
		write(client, auth_req*"\n")
		auth_res = readline(client)
	    open(client_publickey*".txt", "w") do file write(file, client_publickey) end
		auth_success = verify_pk(ip*"<>"*port*"<>"*auth_req, auth_res, client_publickey*".txt")
		rm(client_publickey*".txt")
		if !auth_success
			close(client)
			return
		end

		# they want my publickey
		write(client, publickey*"\n")

		# they want to auth me
		auth_req = readline(client)
		write(client, sign_pk(string(client_ip)*"<>"*client_port*"<>"*msg)*"\n")

		contact_list[Node(client_id, client_ip, client_port, now(), now())] = client

	catch e
		println("client_wants_connection $client error: $e")
	end
end


function i_want_connection(ip, port)


end





#         write(client_sock, "Hello, Client!\n")

#         byte_data = UInt8[]
#         while true
#             byte = read(client_sock, UInt8)
#             push!(byte_data, byte)
#             if length(byte_data) >= length(byte_delimiter) && byte_data[end-length(byte_delimiter)+1:end] == byte_delimiter
#                 byte_data = byte_data[1:end-length(byte_delimiter)]
#                 break
#             end
#         end
#         println("Received byte packet: ", byte_data)

#         write(client_sock, "Received your bytes!\n")

#     catch e
#         println("An error occurred while handling a client: $e")
#     finally
#         close(client_sock)
#     end

# end









function wanna_contact(node::Node) # add this node to kbucket using update kbucket

	# first talk to each other by using each other's public keys'

	# check_credential to each other

	# then you determine a symmetric key and send to them

	# save to your dict

end

function wants_contact(node::Node)

	# other side of above

	# save to your dict

end

function contact(node::Node, message, dtype) # send everything as bytes and datatype

	# if the other node is not in my dict, send NACK

end








function wanna_ping(node::Node)
    # Send a ping
    # Receive a pong
end

function wants_ping(node::Node)
	# Received a ping
	# Now send a pong
end



function wanna_store(key::String, value::String, node::Node)
    # Identify the closest nodes to the key
    # Send the store request to these nodes
end

function wants_store(key::String, value::String, node::Node)
	# check if the hash of the value is really the key
end



function wanna_find_id()

end

function wants_find_node()

end

function wants_find_data(id::String)
	# If the key is in the local storage, return it
    # Otherwise, query closest nodes for the key
end

function find_node(id::String)
    # Return closest nodes to the target ID
end

function find_value(id::String)

end




function join_network(node::Node, bootstrap_node::Node)
    # Use the bootstrap node to find other nodes
    # Populate the routing table using responses from FIND_NODE
end

























function start_server(ip, port)

 	ip_addr = ip isa IPAddr ? ip : ip isa AbstractString ? parse(IPAddr, ip) : error("Invalid IP address format")
    server = listen(ip_addr, port)
    println("Server is running on $ip:$port")

    sock = connect(ip, port)

    while true
        client_sock = accept(server)
        Threads.@spawn handle_client(client_sock)
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

# Threads.@spawn handle_client(client_sock)
