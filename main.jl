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

	# keep alive just msg = message_peer_to_me(peer_client, true) and return if msg == 'alive'

	# todo: this keepalive also calculates "RTT", for regularly updating
	# no handshake fast rtt, will be discarded if nextline's handshake fails anyway

	# Lagging Handshake
	# what if you could perform ping/node/data and then IF you are going to use the results, check handshake
	# what if handshake is lagging, only await it when it matters in the chain...
	# like the final node you reach.. then await all the previous handshakes


	peer_ip, peer_port = getpeername(peer_client)
	peer_id = they_want_connection(peer)	# what if they tell u their random server socket while first initing from their client
	peer = peers[peer_id]

	while 1

		msg = message_peer_to_me(peer_client, true)
		cmd = msg["cmd"]


		if msg=="ping" # todo: we can ping at random times, and there can be an "avg online per hour" "per day" "per week" etc and if it fallse down below a certain threshold...
			message_me_to_peer("pong", port)
			peer.node.last_seen = now(UTC)
			update_bags(peer.node)


		elseif msg=="node" # given a node_id
			closest_nodes = find_closest_nodes(msg["id"])
			message_me_to_peer(closest_nodes, true)


		elseif msg=="data" # given a data_id   ;; msg["id"]


			# I should keep a list of follower-prefixes for each follower (after registering them in follow)
			file = find_in_files("me")
			if file
				if check_space_rule("me", peer_id, file)

					# Todo: either redirect to peer or send directly with a probability
					followers =
					message_me_to_peer(peer_client, "redirect")
					# if none of these redirects work, client take it back from you.

					message_me_to_peer(peer_client, "found")
					#payload_me_to_peer(peer_client, read("space/me/$file", UInt8))
					continue
				end
			end


			# this should be space/follow/master/file.ext && whitelist_get.txt
			file = find_in_files("follow")
			if file

				# update the get file from followed (if checked < 1 min ago)


				message_me_to_peer(peer_client, "found")
				#payload_me_to_peer(peer_client, read("space/follow/$file", UInt8))
				continue
			end




			file = find_in_files("public")
			if file
				message_me_to_peer(peer_client, "found")
				payload_me_to_peer(peer_client, read("space/public/$file", UInt8))
				continue
			end

			message_me_to_peer(peer_client, "node")
			closest_nodes = find_closest_nodes(msg["id"])
			message_me_to_peer(closest_nodes, true)


		elseif msg=="store"
			# ask the "space" ; if you have it, then if you accept it
			# public vs follower case (if you are their follower)
			# or someone wants to store it on your space (put-set)



		elseif msg=="follow"
			# You manually add your followers to a file with prefix permissions
			# or when email system is implemented, they can ask you manually and you have pending permissions
			# OR
			# they are followers already
			# want to update the prefixed files
			# OR
			# they want to change their prefixes



		elseif msg=="end"
			close(peer_client)
			# check if server socket exists too, if not, delete the peer


		end
	end
end











function start_server(port::Int)

    server = listen("0.0.0.0", port) # versus 192.168.1.5 privateip
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
