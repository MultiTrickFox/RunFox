using .Threads

include("util.jl")
include("talk.jl")
include("space.jl")

#


# run me like this: julia main.jl --threads 3,1  => this puts the main in the interactive

println("id is: $id")
println("ip/port is: $ip:$port")


#


# Bring your own Computer









# Dont forget --- you can send JSON(string)   while sending strings - it makes it easier.
# careful: \n and \\n do not go well with crypt.jls


function req_ping(peer_server::TCPSocket) # todo: a socket might not be open, try to open it
	message_me_to_peer(peer_server, Dict("cmd"=>"ping"), json=true)
	return message_peer_to_me(peer_server)
end

function req_node(peer_server::TCPSocket, id::String)
	message_me_to_peer(peer_server, Dict("cmd"=>"node", "id"=>id), json=true)
	return message_peer_to_me(peer_server, json=true)
end

function req_data(peer_server::TCPSocket, id::String)
	message_me_to_peer(peer_server, Dict("cmd"=>"data", "id"=>id), json=true)
	res = message_peer_to_me(peer_server, json=true)
	# res can be:  list of nodes , "ACK" to signal I will send u the data next
	# for the case of followers, they can send me one or multiple follower (which is the list of nodes case)
	return res!="ACK" ? res : payload_peer_to_me(peer_server)
end

function req_store(peer_server::TCPSocket)

end

function req_follow(peer_server::TCPSocket, prefixes::Vector{String})

end





## Server Side - take req, give res

function handle_req(peer_client::TCPSocket) # try

	# if smt with this id is already being handled, return (same id cannot connect to u twice)

	peer_ip, peer_port = getpeername(peer_client)
	peer_id = they_want_connection(peer)
	peer = peers[peer_id]

	while 1

		msg = message_peer_to_me(peer_client, json=true) # we need cmd and args
		cmd = msg["cmd"]

		if msg=="ping" # todo: we can ping at random times, and there can be an "avg online per hour" "per day" "per week" etc and if it fallse down below a certain threshold...
			message_me_to_peer("pong", port)
			peer.node.last_seen = now(UTC)
			update_bags(peer.node)

		elseif msg=="node" # given a node_id
			closest_nodes = find_closest_nodes(msg["id"])

		elseif msg=="data" # given a data_id   ;; msg["id"]

			# A) Regular case
			# B) Your file follower case

			#  ask the "space" ; if you contain it, then for permissions
			# if you dont have it, direct to closest
			# data can be under */
			# if its not under general/  ( its me/ or id/ ) then check the read permissions

		elseif msg=="store"
			# ask the "space" ; if you have it, then if you accept it
			# public vs follower case (if you are their follower)

		# elseif message=="boot" # No such thing, just do "node" on your own ID, then from the closest to you to others, you will keep doing "node" ; do this until you have X amount in your buckets


		elseif msg=="follow"
			# they want to be your follower
			# for certain files




		end
	end
end











function start_server(port::Int)

    server = listen(port)
    println("server is listening..")

    @async begin while 1
        peer_sock = accept(server)
        @spawn handle_req(peer_sock)
    end end

end; @spawn start_server(port)


while true
    sleep(3600) # dont kill the main process
end

## TODO: test case here where you connect to your ip:port and readline() send messages






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
