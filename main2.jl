using Sockets, .Threads

function handle_client(client_sock)

    try

        client_message = readline(client_sock)
        println("Received from client: $client_message")

        response = "Hello, Client!\n"
        write(client_sock, response)
        println("Sent to client: $response")

        byte_data = read(client_sock, 4)  # Adjust size as needed
        println("Received byte packet: ", byte_data)

        response = "Received your bytes!\n"
        write(client_sock, response)
        println("Sent to client: $response")

    catch e
        println("An error occurred while handling a client: $e")
    finally
        close(client_sock)
    end

end

function start_server(ip, port)

 	ip_addr = ip isa IPAddr ? ip : ip isa AbstractString ? parse(IPAddr, ip) : error("Invalid IP address format")

    server = listen(ip_addr, port)
    println("Server is running on $ip:$port")

    while true
        client_sock = accept(server)
        Threads.@spawn handle_client(client_sock)
    end

end

start_server("127.0.0.1", 1234)
