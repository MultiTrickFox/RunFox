using .Threads

include("talk.jl")

#


# Bring your own Computer


# Dont forget --- you can send JSON.stringify(string)   while sending strings - it makes it easier.



## Server Side - take req, give res


function handle_client(peer_client::TCPSocket)

	peer_ip, peer_port = getpeername(peer_client)
	peer_id = handshake_peer_to_me(peer)
	peer = peers[peer_id]

	while 1

		message = readline(peer)

		if message=="ping"
			write(peer, "pong"*"\n")

		elseif message=="find" # node or data , given an id


		elseif message=="node" # given a node_id


		elseif message=="data" # given a data_id (case where this data has an origin, and case where there is none)


		elseif message=="store"



		elseif message=="boot"


		end
	end
end


function start_server(port::Int)

    server = listen(port)
    println("Server is running on $ip:$port")

    while true
        peer_sock = accept(server)
        @spawn handle_client(peer_sock)
    end

end

@spawn start_server(port)









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
