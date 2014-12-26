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
  puts "Found #{services.size} Service(s): #{services.map {|s| s.type }.join(", ")}" 
end