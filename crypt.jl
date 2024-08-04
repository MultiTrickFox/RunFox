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


function hash(message, type="sha2-512")
    cmd_args = []
    if     type == "sha2-256"  type = "sha256"
    elseif type == "sha2-512"  type = "sha512"
	elseif type == "sha3-256"  type = "sha3-256"
    elseif type == "sha3-512"  type = "sha3-512"
	elseif type == "shake-256" type = "shake256"
    else error("Unsupported hash type") end
    io = IOBuffer(message)
    output = read(pipeline(`openssl dgst -$type`, stdin=io), String)
    close(io)
    return split(output)[2]
end


function generate_pk(bits=3072)
    run(`openssl genpkey -algorithm RSA -out privatekey.pem -pkeyopt rsa_keygen_bits:$bits`) # Generate the RSA private key
    run(`openssl rsa -pubout -in privatekey.pem -out publickey.txt`) # Extract the public key from the private key
    publickey = read("publickey.txt", String)
    return publickey
end

function encrypt_pk(message::String, publickey_path="publickey.txt")
    io = IOBuffer(message)
    cmd = pipeline(`openssl pkeyutl -encrypt -pubin -inkey $publickey_path`, stdin=io)
    encrypted_data = read(cmd, String)
    close(io)
    return base64encode(encrypted_data)
end

function decrypt_pk(encrypted_message_base64::String, privatekey_path="privatekey.pem") # todo: case where privatekey is deleted, and in env
    decoded_data = base64decode(encrypted_message_base64)
    io = IOBuffer(decoded_data)
    cmd = pipeline(`openssl pkeyutl -decrypt -inkey $privatekey_path`, stdin=io)
    decrypted_data = read(cmd, String)
    close(io)
    return decrypted_data
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
    # TODO: calculate aes-256 or 512 from the bits_of_key
    cmd = `openssl enc -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    encrypted_data = read(pipeline(cmd, stdin=io), String)
    close(io)
    return base64encode(encrypted_data)
end

function decrypt_sk(encrypted_message_base64::String, key_hex::String, iv_hex::String)
    encrypted_data = base64decode(encrypted_message_base64)
    io = IOBuffer(encrypted_data)
    # TODO: calculate aes-256 or 512 from the bits_of_key
    cmd = `openssl enc -d -aes-$(length(key_hex)*4)-cbc -in - -K $key_hex -iv $iv_hex`
    decrypted_data = read(pipeline(cmd, stdin=io), String)
    close(io)
    return decrypted_data
end


#


function test_crypt()

	hashed = hash("&&&&&;;;;|")
	println("Hashed:", hashed)

	encrypted = encrypt_pk("&&&&&;;;;|")
	println("Encrypted(PK):", encrypted)
	decrypted = decrypt_pk(encrypted)
	println("Decrypted(PK):", decrypted)

	sk,iv = generate_sk()
	encrypted = encrypt_sk("&&&&&;;;;|", sk, iv)
	println("Encrypted(SK):", encrypted)
	decrypted = decrypt_sk(encrypted, sk, iv)
	println("Decrypted(SK):", decrypted)

end
