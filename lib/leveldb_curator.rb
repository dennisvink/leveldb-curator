require "leveldb"
require "socket"
require "bindata"

class Protocol < BinData::Record
    endian  :big
    stringz :database
    stringz :command_word
    stringz :query_key
    stringz :query_value
end

class LeveldbCurator
  def open_databases(databases)
    db_list = {}
    databases.each do |database|
      dbh = LevelDB::DB.new(database)
      db_list[database.to_sym] = dbh
    end
    db_list
  end

  def run_daemon(port, databases)
    unless databases.kind_of?(Array)
      databases = [databases]
    end
    db_handlers = open_databases(databases)
    Socket.udp_server_loop("localhost", port) { |msg, msg_src|
      proto = Protocol.new
      proto.read(msg)

      dbh = db_handlers[proto.database.to_sym]
      if proto.command_word == "put"
        begin
          dbh.put(proto.query_key, proto.query_value)
          msg_src.reply "true"
        rescue => exception
          msg_src.reply exception.to_s
        end
      elsif proto.command_word == "get"
        begin
          msg_src.reply dbh.get(proto.query_key)
        rescue
          msg_src.reply ""
        end
      else
        msg_src.reply "invalid command"
      end
    }
  end

  def initialize(databases = "my_leveldb_database")
    run_daemon(9068, databases)
  end
end
