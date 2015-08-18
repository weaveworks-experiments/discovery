require 'uri'
require 'net/http'

# create a docker swarm token, and return the token ID
def create_swarm()
  uri = URI("https://discovery-stage.hub.docker.com/v1/clusters")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  response = https.request(request)
  response.body
end
