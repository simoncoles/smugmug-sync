#!/usr/bin/env ruby 

# TODO
# Parse option
# rdoc file
# user proper filename manipulation

require 'rubygems'

# You need to have the following rubygems installed
# sudo gem install smirk httparty

require 'smirk'       # This is the SmugMug library
require 'optparse'    # And we need this to parse the command line
require 'yaml'        # And this to get the metadata file in/out of YAML
require 'digest/md5'  # This is so we can take the MD5 hash to check we got the file right
require 'mechanize'   # For downloading photos


# =======================================================================================
# SmugMug API stuff using smirk
# =======================================================================================
# Download a binary file to disk if we need to
def sync_image_file(image, album_directory)
  # Get the EXIF data which is another API call
  exif_data = $smug.find_image_exif(image.id, image.key)
  
  # Getting the URL is a little complex, as there are multiple and we need to get the largest one
  url = image.mediumurl
  url = image.largeurl if image.instance_variable_defined? "@largeurl"
  url = image.xlargeurl if image.instance_variable_defined? "@xlargeurl"
  url = image.x2largeurl if image.instance_variable_defined? "@x2largeurl"
  url = image.x3largeurl if image.instance_variable_defined? "@x3largeurl"
  url = image.originalurl if image.instance_variable_defined? "@originalurl"


  md5sum = image.md5sum 
  caption = image.caption
  keywords = image.keywords
  filename = image.filename

  puts "  Working on file #{filename}" if $verbose
  puts "    URL is #{url}"
  
  image_metadata = {:md5sum => md5sum, :caption => caption, :keywords => keywords, :exif => exif_data}
  
  image_filename = "#{album_directory}/#{filename}"
  metadata_filename = "#{album_directory}/#{filename}.yml"
  
  # Start of with the presumption that we need to download it
  download_it = true
  
  # If the file already exists with metadata then we might not need to download
  if File.exists?("#{image_filename}") && File.exists?("#{metadata_filename}")
    # Load the old Metadata
    existing_metadata = YAML.load_file(metadata_filename)
    # And we don't need to download if the file is ok
    download_it = false if existing_metadata[:md5sum] == md5sum
    puts "    No need to download as we already have it" if $verbose
  end
  
  # This is where we download if needed
  if download_it
    # We didn't have the file, so write things out
    # First dump the metadata
    File.open(metadata_filename, 'w') do |out|
      YAML::dump(image_metadata, out)
    end
    f = $agent.get(url)
    f.save(image_filename)

    # Compute the md5 hash
    downloaded_hash_func = Digest::MD5.new
    downloaded_hash_func.update(IO.read(image_filename))
    downloaded_hash = downloaded_hash_func.hexdigest
    
    # Check the hash is right
    if downloaded_hash == md5sum
      puts "    Downloaded" if $verbose
    else
      puts "Could not get correct md5sum from file downloaded from #{url}"
    end
  end
end


def sync_album(album, destination)
  # check that base_path/category/title ecists
  title = album.title
  category = album.category[:name]
  category_directory = "#{destination}/#{category}"
  album_directory = "#{category_directory}/#{title}"
  # Create the Directories if needed
  Dir.mkdir(category_directory) if !File.exists?(category_directory)
  Dir.mkdir(album_directory) if !File.exists?(album_directory)
  
  puts "Working on Album [#{title}] in Category [#{category}]" if $verbose
  
  # Now get all the images and process them
  # Note we pass true in as the "heavy" parameter which gets the full object, rather than just the id and key
  images = album.images(true)
  images.each do |i|
    sync_image_file(i, album_directory)
  end
end


def sync_with_smugmug
  # Login with Mechanize to download photos
  $agent = Mechanize.new
  page = $agent.get 'https://secure.smugmug.com/login.mg'
  form = page.forms[1]
  form.username = $username
  form.password = $password
  page = $agent.submit form
  # Now our agent is authenticated with SmugMug
  
  
  # Login with Smirk as an API
  $smug = Smirk::Client.new($username, $password)
  albums = $smug.albums
  albums.each do |a|
    sync_album(a, $destination)
  end
  $smug.logout
end

def output_help
  puts "username, password, and destination are mandatory parameters"
  puts "e.g. "
  puts "./smugmug_sync.rb --username YOUR_USERNAME --password YOUR_PASSWORD --destination DIRECTORY"
end

# =======================================================================================
# Process the command line and do something
# =======================================================================================

$verbose = false

# This actually processes what we got on the command line
opts = OptionParser.new 
opts.on('-h', '--help')         { output_help }
opts.on('-V', '--verbose')      {$verbose = true }  
opts.on('-u', '--username USERNAME')  { |u| $username = u }
opts.on('-p', '--password PASSWORD')  { |p| $password = p }
opts.on('-p', '--destination DESTINATION')  { |d| $destination = d }
opts.parse!

# Do the sync
sync_with_smugmug

