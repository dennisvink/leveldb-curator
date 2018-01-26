# LevelDB Curator

The LevelDB Curator gem allows you to manage one or more LevelDB databases from
one or more clients concurrently. It listens on UDP port `9068` on localhost
for `put` and `get` commands.

## Installation ##

```
bundle install
gem build leveldb_curator.gemspec
gem install ./leveldb_curator-0.1.0.gem
```

## Example daemon ##

```ruby
require "leveldb_curator"

LeveldbCurator.new(
  %w(foobar_database barfoo_database)
)
```

The above example will initialize two leveldb databases: foobar_database
and barfoo_database. It will keep running until the process is terminated.

## Example client implementation

```ruby
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

```

The client code does not depend on this gem nor on leveldb. It only sends out
UDP queries and returns the daemon's response. Therefore you can use this in
multiple projects querying the same database.

### Credits

I've borrowed the UDP client/server code from this gist:

https://gist.github.com/omnisis/3998752

Thanks to [@omnisis] for posting it.
