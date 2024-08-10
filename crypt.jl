using Base
using Dates
using Base64

#


# Terminal injection prevention:

# Direct Command Execution:
# By constructing the command using backticks and explicitly specifying the command and its arguments within Cmd objects,
# Julia handles these as distinct entities, not as part of a shell where interpretation or expansion of special characters could occur. This approach avoids the common pitfalls of shell-based command execution where input can be interpreted as additional commands or parameters.

# Use of IOBuffer:
# The use of an IOBuffer for input data provides a way to stream data directly to the command's stdin without involving the shell's command parsing mechanisms.
# This means even if the input data contains potentially malicious sequences (like shell commands or special characters), they are treated as plain data, not executable code.


#


function hashi(message, type="shake-256", outbits=256) # TODO: this doesnt work when you change type here
	type = get(Dict(
		"sha2-256" => "sha256",
		"sha2-512" => "sha512",
		"sha3-256" => "sha3-256",
		"sha3-512" => "sha3-512",
		"shake-256" => "shake256",
		"shake-512" => "shake512",
	), type, type)
    io = IOBuffer(message)
    output = read(pipeline( occursin("shake", type) ? `openssl dgst -$type` : `openssl dgst -$type -xoflen $(Int(outbits/8))` , stdin=io), String)
    close(io)
    return String(split(output)[2])
end


function generate_pk(bits=3072)
    run(`openssl genpkey -algorithm RSA -out privatekey.pem -pkeyopt rsa_keygen_bits:$bits`) # Generate the RSA private key
    run(`openssl rsa -pubout -in privatekey.pem -out publickey.pem`) # Extract the public key from the private key
    publickey = read("publickey.pem", String)
    return publickey
end

function encrypt_pk(message::String, publickey_path="publickey.pem")
    io = IOBuffer(message)
    cmd = pipeline(`openssl pkeyutl -encrypt -pubin -inkey $publickey_path`, stdin=io)
    encrypted_data = read(cmd, String)
    close(io)
    return base64encode(encrypted_data)
end
function decrypt_pk(encrypted_message_base64::String, privatekey_path="privatekey.pem")
    decoded_data = base64decode(encrypted_message_base64)
    io = IOBuffer(decoded_data)
    cmd = pipeline(`openssl pkeyutl -decrypt -inkey $privatekey_path`, stdin=io)
    decrypted_data = read(cmd, String)
    close(io)
    return decrypted_data
end

function sign_pk(message::String, privatekey_path="privatekey.pem")
    io = IOBuffer(message)
    cmd = pipeline(`openssl dgst -sha256 -sign $privatekey_path`, stdin=io)
    signed_data = read(cmd, String)
    close(io)
    return base64encode(signed_data)  # Return the base64-encoded signed data
end
function verify_pk(data::String, signed_data_base64::String, publickey_path="publickey.pem")
	io_data = IOBuffer(data)
    signed_data = base64decode(signed_data_base64)
    signature_path = hashi(rand(UInt8,16))
    open(signature_path, "w") do file write(file, signed_data) end
    cmd = pipeline(`openssl dgst -sha256 -verify $publickey_path -signature $signature_path`, stdin=io_data)
    verification = read(cmd, String)
    close(io_data)
    rm(signature_path)
    return startswith(verification,"Verified OK")
end


function generate_sk(bits_key=256, bits_iv=128)
    key_bytes = rand(UInt8, bits_key÷8)
    key_hex = bytes2hex(key_bytes)
    iv_bytes = rand(UInt8, bits_iv÷8)
    iv_hex = bytes2hex(iv_bytes)
    return key_hex, iv_hex
end

function encrypt_sk(message::String, key_hex::String, iv_hex::String)
    io = IOBuffer(message)
    cmd = `openssl enc -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    encrypted_data = read(pipeline(cmd, stdin=io), String)
    close(io)
    return base64encode(encrypted_data)
end
function decrypt_sk(encrypted_message_base64::String, key_hex::String, iv_hex::String)
    encrypted_data = base64decode(encrypted_message_base64)
    io = IOBuffer(encrypted_data)
    cmd = `openssl enc -d -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    decrypted_data = read(pipeline(cmd, stdin=io), String)
    close(io)
    return decrypted_data
end

function encrypt_sk(data::Vector{UInt8}, key_hex::String, iv_hex::String)
    io = IOBuffer(data)
    cmd = `openssl enc -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    encrypted_data = read(pipeline(cmd, stdin=io))
    close(io)
    return encrypted_data
end
function decrypt_sk(encrypted_data::Vector{UInt8}, key_hex::String, iv_hex::String)
    io = IOBuffer(encrypted_data)
    cmd = `openssl enc -d -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    decrypted_data = read(pipeline(cmd, stdin=io))
    close(io)
    return decrypted_data
end


#


const publickey = !isfile("publickey.pem") ? generate_pk() : read("publickey.pem", String)
const id = hashi(publickey)
println("id is: $id")
const privatekey = read("privatekey.pem")


#

function test_crypt()

	hashed = hashi("&&&&&;;;;|")
	println("Hashed:", hashed)

	encrypted = encrypt_pk("&&&&&;;;;|")
	println("Encrypted(PK):", encrypted)
	decrypted = decrypt_pk(encrypted)
	println("Decrypted(PK):", decrypted)

	signed = sign_pk("&&&&&;;;;|")
	println("Signed(PK):", signed)
	verified = verify_pk("&&&&&;;;;|", signed)
	println("Verified(PK):", verified)

	sk,iv = generate_sk()
	encrypted = encrypt_sk("&&&&&;;;;|", sk, iv)
	println("Encrypted(SK):", encrypted)
	decrypted = decrypt_sk(encrypted, sk, iv)
	println("Decrypted(SK):", decrypted)

	randombytes = rand(UInt8, 4)
	println("randombytes:", randombytes)
	encrypted = encrypt_sk(randombytes, sk, iv)
	println("Encrypted(SK)(bytes):", encrypted)
	decrypted = decrypt_sk(encrypted, sk, iv)
	println("Decrypted(SK)(bytes):", decrypted)

end; test_crypt()
