require 'net/http'
require 'addressable/uri'
require 'json'

require File.expand_path(File.join(File.dirname(__FILE__), 'jsonrpc', 'version'))
require File.expand_path(File.join(File.dirname(__FILE__), 'jsonrpc', 'exceptions'))

module JsonRPC

  class Client
    @@id = 0
    
    def initialize(url)
      @address    = Addressable::URI.parse(url)
    end

    def request(method, params = [])
      @@id += 1 # increment id for each request 
      
      result = {}
      h = {"Content-Type" => "application/json"}
      Net::HTTP.start(@address.host, @address.port) do |connection|
	      json = {:method => method.to_s, :params => params, id: @@id, version: "1.0"}.to_json
	      result = JSON.parse(connection.post(@address.path, json, h).body)
      end
      
      if error = result["error"]
        raise JsonRPCError, result
      end
      result
    end

  end

end
