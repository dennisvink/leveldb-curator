require 'socket'
require 'bindata'

class Protocol < BinData::Record
    endian  :big
    stringz :database
    stringz :command_word
    stringz :query_key
    stringz :query_value
end

def get_answer(sock)
    msg, sender = sock.recvfrom(1024)
    msg
end

def send_request(sock, data)
    sock.send(data, 0, "localhost", 9068)
end

def query(database, command, query_key, query_value = "")
    add_request = Protocol.new
    add_request.database = database
    add_request.command_word = command
    add_request.query_key = query_key
    add_request.query_value = query_value
    send_request(@s, add_request.to_binary_s)
    get_answer(@s)
end

@s = UDPSocket.new

query("foobar_database", "put", "foo", "bar")
query("barfoo_database", "put", "bar", "foo")
response = query("foobar_database", "get", "foo")
response2 = query("barfoo_database", "get", "bar")

puts response
puts response2
