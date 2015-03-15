#code from https://practicingruby.com/articles/implementing-an-http-file-server
#modified for web_tech project, Foundation of Web Technologies (beta), Tealeaf Academy 

require 'socket'
require 'uri'

# Files will be served from this directory
WEB_ROOT = './documents'

# Map extensions to their content type
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

#code from Rack::File to sanitize conversion of URI to file path
def requested_file(message_line)
  request_uri  = message_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end

server = TCPServer.open('localhost', 2000)
puts "HTTP Server ready to accept requests!"

loop do
  connection = server.accept
  puts "Opening a connection for request:"
  message_line = connection.gets
  puts "My message_line is #{message_line}"
#  while message_line = connection.gets
#    puts message_line
#    break if message_line.chomp == ""
#  end

  puts "Sending response.."
  
  path = requested_file(message_line)
  
  path = File.join(path, 'index.html') if File.directory?(path)
  
  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      connection.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{content_type(file)}\r\n" +
                   "Content-Length: #{file.size}\r\n" +
                   "Connection: close\r\n"

      connection.print "\r\n"

      # write the contents of the file to the connection
      IO.copy_stream(file, connection)
    end
  else
    message = "File not found\n"
    connection.puts message
  end
end
