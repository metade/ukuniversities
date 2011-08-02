require 'sinatra'
require 'sinatra/respond_to'
require 'ostruct'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'erb'

require 'active_support'
require 'active_support/cache'
require 'active_support/cache/dalli_store'

Sinatra::Application.register Sinatra::RespondTo

configure do
  mime_type :kml, 'application/vnd.google-earth.kml+xml'
  
  if ENV['cache'] == 'dalli'
    CACHE = ActiveSupport::Cache::DalliStore.new
  else
    CACHE = ActiveSupport::Cache::FileStore.new('tmp')
  end
end

before do
  response.headers["Access-Control-Allow-Origin"] = "*"
end

get '/universities' do
  @universities = University.all
  
  respond_to do |wants|
    wants.json { @universities.to_json }
    wants.kml { erb :universities }
  end
end

get '/universities/:id' do |id|
  @university = University.all.detect { |u| u.hesacode == id }
  
  respond_to do |wants|
    wants.json { @university.to_json }
    wants.kml { erb :universities }
  end
end

get '/universities/by/group/:group' do |group|
  @universities = University.all.select { |u| u.unigroup =~ /#{group}/i }
  
  respond_to do |wants|
    wants.json { @universities.to_json }
    wants.kml { erb :universities }
  end
end

get '/universities/by/fees/lt/:cost' do |cost|
  @universities = University.all.select { |u| !u.maxtuitionfee.blank? and u.maxtuitionfee.to_i < cost.to_i }
  
  respond_to do |wants|
    wants.json { @universities.to_json }
    wants.kml { erb :universities }
  end
end

class OpenStruct
  def to_json(*a)
    table.to_json(a)
  end
end

GOOGLEDOC = '0AlmchlQZetn7dHJ2MW40UHU5MWZmNlVBR0dBbzNkNEE'
class University < OpenStruct
  def self.all
    url = "http://spreadsheets.google.com/feeds/list/#{GOOGLEDOC}/1/public/values"
    CACHE.fetch(url, :expires_in => 30.seconds) do
      puts "FETCHING #{url}"
      doc = Nokogiri::XML(open(url))
      doc.xpath('//atom:entry', 'atom' => 'http://www.w3.org/2005/Atom').map do |entry|
        result = {}
        entry.children.
          select  { |c| c.namespace.prefix == 'gsx' }.
          each    { |c| result[c.name] = c.text }
        self.new(result)
      end
    end
  end
end
