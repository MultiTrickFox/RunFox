import Base.:(==) # wtf

using Dates
using Sockets, .Threads

include("talk.jl")

#

const publickey = !isfile("publickey.txt") ? generate_pk() : read("publickey.txt", String)
const id = hashish(publickey)
println("id is: $id")

const privatekey == read("privatekey.pem")

#
