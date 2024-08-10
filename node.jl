import Base.:(==)
using Dates

include("crypt.jl")

#


mutable struct Node
    id::String
    ip::String
    port::Int
    first_seen::DateTime
    last_seen::DateTime
end
==(n1::Node, n2::Node) = (n1.id == n2.id) && (n1.ip == n2.ip) && (n1.port == n2.port)


mutable struct Data # this is stored on disk with "id.uint8" or "id - node.id"
	id::String # hashi(content)		;;
	name::String # string filename  ;;  myfile.txt
	node::Node # nullable
	last_seen::DateTime # nullable
end
==(d1::Data, d2::Data) = (d1.id == d2.id) && (d1.node == d2.node)


#


function xor_distance(id1::String, id2::String, numerical=false)
    xor_result = parse(BigInt, id1, base=16) ⊻ parse(BigInt, id2, base=16)
    if numerical return xor_result end
    bool_array = Bool[]
    for i in (length(id1)*4-1):-1:0 # Shift the xor_result right by 'i' bits and check the least significant bit
        push!(bool_array, (xor_result >> i) & 1 == 1)
    end
    return bool_array
end


#


const num_bags = 256
const per_bag = 4


struct Bag # for each bag (1 to 256) it starts from MSB digit to LSB, meaning Kth is the closest one to us
	k::Int # range is 1_{0000}*k to 1_{1111}*k
	nodes::Vector{Node}
end

const bags = [ Bag(k,[]) for k in 1:num_bags ]


function update_bags(node::Node)
	println("updating kbag for $node.id")

	distance = xor_distance(id, node.id)
	println(distance)

	for (i,bit) in enumerate(distance)
		if bit # Find the appropriate bucket based on distance # bags[i]
			idx = findfirst(e->e==node, bags[i].nodes)
			if idx != nothing # If the node is already in the bucket, update the last_seen //move it to the end
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


function find_closest_nodes(id_other::String, num=per_bag)
	println("checking kbag for $id_other")

	nodes = []

    distance = xor_distance(id, id_other)
    println(distance)

	idx = findfirst(e->e, distance)
	println("closest in $idx th bag")

	for i in idx:-1:1 # in julia, a[end-2:end] means last -3 elements gg enjoy :)
		if length(bags[i].nodes)==0 # if length(bags[i].items)==0 continue end
			println("bag $i empty")
			continue
		end
		sorted_items = sort(bags[i].nodes, by=e->xor_distance(e.id, id_other, true))
		append!(nodes, sorted_items[1:min(num-length(nodes),length(sorted_items))])
		if length(nodes)==num break end
	end

    return nodes
end


#


function print_bags()
	for bag in bags
		if length(bag.nodes)==0 continue end
		println("Bag $(bag.k)")
		for node in sort(bag.nodes, by=e->xor_distance(e.id, id, true), rev=true)
			println("\t$node")
		end
	end
end


#

# function test_node()

# 	update_bags(Node(hashi("aieaera"), "localhost", 30, now(), now()))
# 	update_bags(Node(hashi("qweqws"), "localhost", 31, now(), now()))
# 	update_bags(Node(hashi("zimbabwe"), "localhost", 32, now(), now()))
# 	update_bags(Node(hashi("tupitu"), "localhost", 33, now(), now()))
# 	update_bags(Node(hashi("zumar"), "localhost", 34, now(), now()))
# 	update_bags(Node(hashi("supaman"), "localhost", 35, now(), now()))
# 	update_bags(Node(hashi("kapiku"), "localhost", 36, now(), now()))
# 	update_bags(Node(hashi("zomon"), "localhost", 37, now(), now()))
# 	update_bags(Node(hashi("somon"), "localhost", 38, now(), now()))
# 	update_bags(Node(hashi("luparr"), "localhost", 39, now(), now()))
# 	update_bags(Node(hashi("worsh"), "localhost", 40, now(), now()))
# 	update_bags(Node(hashi("kirpik"), "localhost", 41, now(), now()))
# 	update_bags(Node(hashi("kopek"), "localhost", 42, now(), now()))
# 	update_bags(Node(hashi("kedi"), "localhost", 43, now(), now()))
# 	update_bags(Node(hashi("lambda"), "localhost", 44, now(), now()))
# 	update_bags(Node(hashi("yumenyi"), "localhost", 45, now(), now()))

# 	print_bags()

# 	nodeX = find_closest_nodes(hashi("banditos"))
# 	println(nodeX)

# end; test_node()
