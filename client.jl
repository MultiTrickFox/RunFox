using Sockets

# https://docs.julialang.org/en/v1/manual/variables/

#

byte_delimiter = UInt8[0xFF, 0xFE, 0xFD]

function communicate_with_server(ip, port)

    sock = connect(ip, port)

    try

        send_string = "Hello, Server!\n"
        write(sock, send_string)
        println("Sent to peer: $send_string")

        response = readline(sock)
        println("Received from peer: $response")

        byte_packet = UInt8[0x01, 0x02, 0x03, 0x04]
        write(sock, byte_packet)
        write(sock, byte_delimiter)

        final_response = readline(sock)
        println("Final response from server: $final_response")

    catch e
        println("An error occurred: $e")
    finally
        close(sock)
    end

end

communicate_with_server("127.0.0.1", 1234)
