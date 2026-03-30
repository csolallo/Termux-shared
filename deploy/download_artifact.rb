# use the github api to find and downoad the latest artifact

require 'json'
require 'net/https'
require 'open-uri'

RESPONSE_TEMPLATE = {
  "headers" => {},
  "body"    => {}
}

# on expected responses, returns json shaped like
# {
#   headers: {}
#   body: {}
# }
# will raise StandardError on unexpected responses
def fetch(token, url)
  uri = URI.parse(url)
  request = Net::HTTP.new(uri.host, 443)
  request.use_ssl = true
  request.ca_path = ENV['SSL_CERT_DIR'] || '/usr/lib/ssl'
  request.ca_file = ENV['SSL_CERT_FILE'] || '/usr/lib/ssl/cert.pem'
  
  headers = {
    "Accept" => "application/vnd.github+json",
    "Authorization" => "Bearer #{token}" 
  }
  
  resp = request.get(uri.path, headers)
  case resp
  when Net::HTTPOK
    response = Hash.new(RESPONSE_TEMPLATE)
    response["body"] = JSON.parse(resp.body)

    return yield response
  when Net::HTTPFound # redirect
    response = Hash.new(RESPONSE_TEMPLATE)
    response["headers"] = {"location" => resp.header["location"]}

    return yield response  
  else
    if resp.respond_to?(:body_permitted?)
      raise resp.body
    end
    raise "Unexpected server response #{resp.class.name} returned."
  end
end

# check preconditions
[ENV['TOKEN'], ENV['APP']].each do |tok|
  if tok.nil?
    STDERR.puts "#{tok} environment variable not found."
    exit(-1)
  end
end 

begin
  token = ENV['TOKEN']

  # get the name and the download_url of the most recent artifact
  archive_details = fetch(token, 'https://api.github.com/repos/csolallo/Groceries/actions/artifacts') do |json|
    json = json["body"]

    artifact_count = json["total_count"]
    unless artifact_count == 1
      raise "Expected 1 artifact, got #{artifact_count}."
    end
    
    {
      id: json["artifacts"][0]["id"],
      name: json["artifacts"][0]["name"],
      archive_download_url: json["artifacts"][0]["archive_download_url"]
    }
  end
  artifact_id = archive_details[:id]
  artifact_name = archive_details[:name]
  artifact_url = archive_details[:archive_download_url]
  
  if artifact_id.nil? || artifact_name.nil?|| artifact_url.nil?
    raise "Expected fields not found in response. Check github action for errors."
  end

  # get the actual download link
  redirect_url = fetch(token, artifact_url) do |json|
    json["headers"]["location"]
  end
  
  # let's defer to wget at this point
  %x{wget -q -O #{artifact_name}.zip "#{redirect_url}"}
rescue => e 
  STDERR.puts e.message
  exit(-1)  
end
