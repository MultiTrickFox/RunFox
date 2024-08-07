import Base.:(==)
using Dates

include("crypt.jl")

#


mutable struct Node # a person can own multiple nodes with same id, different ip/port
    id::String # hash of the publickey
    ip::String
    port::Int
    first_seen::DateTime
    last_seen::DateTime # todo: we can ping at random times, and there can be an "avg online per hour" "per day" "per week" etc and if it fallse down below a certain threshold...
end
==(n1::Node, n2::Node) = (n1.id == n2.id) && (n1.ip == n2.ip) && (n1.port == n2.port)


mutable struct Data # this is stored on disk with "id.uint8" or "id - node.id"
	id::String # hash of node_id+a_title_i_pick
	node::Node # nullable
	last_seen::DateTime # nullable
end
==(d1::Data, d2::Data) = (d1.id == d2.id) && (d1.node == d2.node)

# when i receive data, if id != hash(data) then I ask it to the origin node, ( then origin node cant be null! - else its a badactor )
# else its a normal mode data

# when a Data is requested, this node will check its content wrt origin (if its not null)
# if original has not changed, it will send the value
# if the original has changed, it will forward you to origin

# the origin has followers, so if you ask the origin, it can forward you to one of its followers

#


function xor_distance(id1::String, id2::String, numerical=false) # hexadecimal hash strings
    xor_result = parse(BigInt, id1, base=16) ⊻ parse(BigInt, id2, base=16)
    if numerical return xor_result end
    bool_array = Bool[]
    for i in (length(id1)*4-1):-1:0 # Shift the xor_result right by 'i' bits and check the least significant bit
        push!(bool_array, (xor_result >> i) & 1 == 1)
    end
    return bool_array
end



const num_bags = 256 #8 # 2^8 = 256
const per_bag = 4

# for each bag (1 to 256)  # it starts from last digit to first digit

struct Bag
	k::Int # range is 1_0000 to 1_1111
	nodes::Vector{Node}
end
# keep the node's sorted by last_seen time, oldest one's at the beginning, newest one's at the end.


# bags go from K to 1 in closeness, meaning Kth is the closest one to us
# 1 is the largest, bc 1st sigbit
const bags = [ Bag(k,[]) for k in 1:num_bags ]

# in julia, a[end-2:end] means last -3 elements gg enjoy :)




# given a distance result, check which leftmostmax index is true ;; thats the KBucket's k

# todo: this function should acquire lock, bc of modification

function update_bags(node::Node)
	distance = xor_distance(id, node.id)

	println("updating kbag for $node")
	println(distance)

	for (i,bit) in enumerate(distance)
		if bit # Find the appropriate bucket based on distance # bags[i]
			# If the node is already in the bucket, update the last_seen //move it to the end
			idx = findfirst(e->e==node, bags[i].nodes) # ==(node) means e -> e == node
			if idx != nothing
				bags[i][idx].last_seen = node.last_seen # we should pop it then add it -> for seen order
				println("updated last seen")
			elseif length(bags[i].nodes) < per_bag # If the bucket is not full, add the node
        		push!(bags[i].nodes, node)
          		println("pushed to bag $i")
			else # If the bucket is full, ping the oldest seen //ping the first node
				min_node = bags[i].nodes[argmin([e.last_seen for e in bags[i].nodes])]
				println("checking least recently seen bag $i")
				push!(bags[i].nodes, node) # todo: how to ping
			end
			break
		end
	end
end

function find_closest_nodes(id_other::String, num=per_bag) # this can be a data_id or node_id

	# if this id is me
	# if this id is data in me
	# else ...:

	nodes = []

	# find closest bucket

    distance = xor_distance(id, id_other)
    println(distance)

	idx = findfirst(e->e, distance)
	println("closest in $idx th bag")

	for i in idx:-1:1
		#if length(bags[i].items)==0 continue end
		if length(bags[i].nodes)==0
			println("bag $i empty")
			continue
		end
		sorted_items = sort(bags[i].nodes, by=e->xor_distance(e.id, id_other, true))
		append!(nodes, sorted_items[1:min(num-length(nodes),length(sorted_items))])
		if length(nodes)==num break end
	end

    return nodes
end



# update_bags(Node(hashish("hello there"), "localhost", 30, now(), now()))
# update_bags(Node(hashish("my friend"), "localhost", 31, now(), now()))
# update_bags(Node(hashish("yowyowoyow"), "localhost", 33, now(), now()))
# update_bags(Node(hashish("ei ei ei"), "localhost", 30, now(), now()))
# update_bags(Node(hashish("yo yo yo"), "localhost", 31, now(), now()))
# update_bags(Node(hashish("supman"), "localhost", 33, now(), now()))

# println(bags)

# nodeX = find_closest_nodes(hashish("qweqweqw"))
# println(nodeX)
