using Dates
using JSON

#


is_scalar_type(val) = isa(val, Union{
    Int, Int8, Int16, Int32, Int64,
    UInt, UInt8, UInt16, UInt32, UInt64,
    Float32, Float64,
    Complex{Float32}, Complex{Float64},
    BigInt, BigFloat,
    Rational,
    Bool,
    Char,
    String,
    Date, Time, DateTime,
})


function serialize_struct(s)
    if is_scalar_type(s) 	   # Scalar
        return s
    elseif s isa AbstractDict  # Dict
        return Dict(k => serialize_struct(v) for (k, v) in s)
    elseif s isa AbstractArray # Array
        return map(serialize_struct, s)
	elseif s isa AbstractSet   # Set
        return Set(map(serialize_struct, collect(s)))  # Convert set to an iterable, apply serialization, then convert back to set
    else 					   # Struct
        return Dict("type" => string(typeof(s)), "data" => Dict(fn => serialize_struct(getfield(s, fn)) for fn in fieldnames(typeof(s))))
    end
end

function pack_json(s)
    dict = serialize_struct(s)
    return JSON.json(dict)
end


function deserialize_struct(d, allowed_types=[])
    if is_scalar_type(d) 				   # Scalar
        return d
    elseif d isa Dict && "type" in keys(d) # Struct
        type = d["type"]
        fields = d["data"]
        if type in allowed_types
        	type = eval(Meta.parse(d["type"]))
         	args = [deserialize_struct(fields[string(fieldname)], allowed_types) for fieldname in fieldnames(type)]
            return type(args...)
        else throw(ErrorException("Unauthorized or unknown type encountered in json: $type"))
        end
    elseif d isa Dict					   # Dict
        return Dict(k => deserialize_struct(v) for (k, v) in d)
    elseif d isa AbstractArray 			   # Array
        return map(deserialize_struct, d)
    elseif d isa Set 			 		   # Set
        return Set(map(deserialize_struct, collect(d)))
    end
end

function unpack_json(json_str, allowed_types=[])
    dict = JSON.parse(json_str)
    return deserialize_struct(dict, allowed_types)
end


#



## Tests ##


# struct Address
#     city::String
#     zipcode::Int
# end

# struct Person
#     name::String
#     age::Int
#     address::Address
# end


# # Create an instance of Person
# julia_person = Person("Alice", 30, Address("New York", 10001))
# println("Struct Initially:")
# println(julia_person)

# # Serialize the Person instance to JSON
# json_data = pack_json(julia_person)
# println("Serialized JSON:")
# println(json_data)

# # Deserialize the JSON back to a Person struct
# reconstructed_person = unpack_json(json_data, ["Person", "Address"])
# println("Deserialized Person Struct:")
# println(reconstructed_person)
