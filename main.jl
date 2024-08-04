using Base
using Dates

include("crypt.jl")

#

publickey = !isfile("publickey.txt") ? generate_pk() : read("publickey.txt", String)
id = hash(publickey)
println("your id is: $id")

#



#

struct Node
    id::String
    ip::String
    port::Int
    last_seen::DateTime
end



#

# XOR distance metric
function xor_distance(id1::String, id2::String)
    return parse(BigInt, id1, base=16) ⊻ parse(BigInt, id2, base=16)
end

# Update the k-bucket with a given node
function update_kbucket(routing_table, node::Node)
    # Find the appropriate bucket based on distance
    # If the bucket is not full, add the node
    # If the node is already in the bucket, move it to the end
    # If the bucket is full, consider node replacement strategies
end

# Find the k closest nodes
function find_closest_nodes(routing_table, target_id::String, k::Int)
    # Use the XOR distance to sort and find the closest nodes
end

#

# Node PING to check if another node is alive
function ping(node::Node)
    # Send a ping request
    # Receive a response
end

# Store a key-value pair in the network
function store(key::String, value::String, node::Node)
    # Identify the closest nodes to the key
    # Send the store request to these nodes
end

# Find node by ID
function find_node(target_id::String)
    # Return closest nodes to the target ID
end

# Find value by key
function find_value(key::String)
    # If the key is in the local storage, return it
    # Otherwise, query closest nodes for the key
end

#

function join_network(node::Node, bootstrap_node::Node)
    # Use the bootstrap node to find other nodes
    # Populate the routing table using responses from FIND_NODE
end

function refresh_buckets()
    # Periodically refresh buckets to prevent stale entries
    # Could use scheduled tasks in Julia
end

#

my_node = Node(id, "localhost", 8080, now())
bootstrap_node = Node("bootstrap_node_id", "bootstrap_ip", 8081, now())
join_network(my_node, bootstrap_node)
