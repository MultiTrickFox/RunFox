using .Threads

include("talk.jl")

#


# Bring your own Computer





# Dont forget --- you can send JSON(string)   while sending strings - it makes it easier.
# careful: \n and \\n do not go well with crypt.jls

# message_peer_to_me  --> make me auto json?
# message_me_to_peer



## Server Side - take req, give res

function handle_client(peer_client::TCPSocket)

	peer_ip, peer_port = getpeername(peer_client)
	peer_id = handshake_peer_to_me(peer)
	peer = peers[peer_id]

	while 1

		msg = message_peer_to_me(peer_client, json=true) # we need cmd and args
		cmd = msg["cmd"]

		if msg=="ping"
			message_me_to_peer(peer_client, "pong", json=false)
			# update the kbucket
			# update the last_seen time (also in update kbucket)

		elseif msg=="node" # given a node_id
			closest_nodes = find_closest_nodes(msg["id"])
			# some of these ports may be unfilled (if they only connected to us with their_client -> our_server)
			# in that case receiver is supposed to ping them.
			# but they dont know where to ping them... try 9696 by default, but if its unresponsive, u gotta check if others connected to their server

		elseif msg=="data" # given a data_id
			#  ask the "space" ; if you contain it, then for permissions
			# if you dont have it, direct to closest

		elseif msg=="nodedata"
			# :: the node-data case :: (only here)
			# on the origin->follower case
			# send a special redirect message type

		elseif msg=="store"
			# ask the "space" ; if you have it, then if you accept it
			# public vs follower case

		# elseif message=="boot" # No such thing, just do "node" on your own ID, then from the closest to you to others, you will keep doing "node" ; do this until you have X amount in your buckets


		end
	end
end


function start_server(port::Int)

    server = listen(port)
    println("Server is running on $ip:$port")

    @async begin while 1
        peer_sock = accept(server)
        @spawn handle_client(peer_sock)
    end end

end; @async start_server(port)


while true
    sleep(3600) # dont kill the main process
end








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
