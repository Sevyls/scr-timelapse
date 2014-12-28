require 'playful/ssdp'
require 'set'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'addressable/uri'
require_relative 'service'
require_relative 'jsonrpc'

SONY_ST_HEADER = 'urn:schemas-sony-com:service:ScalarWebAPI:1'
SONY_AV_URN = 'urn:schemas-sony-com:av'
INTERVAL = 10

def every_n_seconds(n)
	loop do
	  before = Time.now
	  yield
	  interval = n - (Time.now - before)
	  sleep(interval) if interval > 0
  end
end

puts 'Searching for cameras...'
response_list = Playful::SSDP.search SONY_ST_HEADER

if response_list.empty?
  puts 'No cameras found.' 
else
  locations = Set.new
  response_list.each do |response|
    locations << response[:location]
  end
  
  
  desc_xml = Nokogiri::XML(open(locations.first))
  camera_name = desc_xml.xpath(
    '/xmlns:root/xmlns:device/xmlns:friendlyName/text()', 
    'xmlns' => 'urn:schemas-upnp-org:device-1-0').to_s
  puts "Found camera: #{camera_name}"
  puts "Searching for services..."
    
  services_xml = desc_xml.xpath('//av:X_ScalarWebAPI_Service', 
    'av' => SONY_AV_URN)
    
  services = Array.new  
  services_xml.each do |service_xml|
    service = Service.new
    service.type = service_xml.xpath('av:X_ScalarWebAPI_ServiceType/text()', 
      'av' => SONY_AV_URN).to_s
    service.url = service_xml.xpath('av:X_ScalarWebAPI_ActionList_URL/text()', 
      'av' => SONY_AV_URN).to_s  
    services << service
  end
  
  camera_service = services.select {|s| s.type == 'camera'}.first
  
  puts camera_service.inspect
  
  # Get camera status
  client = JsonRPC::Client.new("#{camera_service.url}/#{camera_service.type}")
  response = client.request("getEvent", [false])
  camera_status = response["result"][1]["cameraStatus"]
  puts "Camera status: #{camera_status}"
  
  if camera_status == 'IDLE'
    # check availabilty of IntervalStillRec methods
    supported_apis = client.request("getMethodTypes", ["1.0"])['results'].map! {|e| e[0]}
    interval_still_rec_supported = not(supported_apis.select {|e| e == 'startIntervalStillRec'}.empty?)
    
    puts 'Starting timelapse capturing...'
    
    if interval_still_rec_supported
      response = client.request("setIntervalTime", [{"intervalTimeSec" => INTERVAL}])
      puts response
    
      response = client.request("startIntervalStillRec")
      puts response
    else 
      # i.e. Sony DSC-QX10 does not support IntervalStillRec methods...
      
      every_n_seconds(INTERVAL) do
        # shoot still
        response = client.request("actTakePicture")
        puts response
      end
    end
    
  else
    puts 'Camera not IDLE... exiting.'
  end
  
  
end