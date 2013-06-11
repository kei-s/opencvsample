lib = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH << File.expand_path(lib)

require 'bundler/setup'
require 'sinatra'
require "sinatra/reloader" if development?
require 'haml'
require 'open-uri'
require 'fileutils'
require 'aws/s3'
require 'RMagick'
require 'opencv'
require 'awesome_print'
require 'debugger'
require 'eye_detect'

set :haml, {:format => :html5 }

get '/image' do
  haml :image
end

use_original_name = false

def new_name(url)
  Digest::SHA1.hexdigest(url) + File.extname(url).downcase
end

def fit_name_350(name)
  name.sub(/(#{File.extname(name)})$/, "_350\\1")
end

def fit_name_600(name)
  name.sub(/(#{File.extname(name)})$/, "_600\\1")
end

def fit_name_face(name)
  name.sub(/(#{File.extname(name)})$/, "_face\\1")
end

get '/up' do
  @user = params[:user]
  @url = params[:url]
  @method = params[:method]
  #s3 = ::AWS::S3.new(
  #  access_key_id:     ENV["S3_ACCESS_KEY"],
  #  secret_access_key: ENV["S3_SECRET"]
  #)
  #bucket_name = "my-web-imags"
  #s3.buckets.create(bucket_name) unless s3.buckets[bucket_name].exists?
  #bucket = s3.buckets[bucket_name]
  #image_prefix = "images"
  image_name = use_original_name ? File.basename(@url) : new_name(@url)
  #image_path = File.join(image_prefix, @user, image_name)
  #object_350 = bucket.objects[fit_name_350(image_path)]
  #bject_face = bucket.objects[fit_name_face(image_path)]

  open(@url) do |sock|
    temp = Tempfile.open(image_name)
    temp.binmode
    temp.write(sock.read)

    output = "public/temp.jpg"
    temp_image = Magick::Image.read(temp.path).first
    temp_image.resize_to_fit!(350)
    temp_image.write(output)
    #object_350.write(file: fit_name_350(temp.path), acl: :public_read, content_type: sock.content_type)

    image = EyeDetect.load(output)
    image.send("#{@method}!") if image.respond_to?("#{@method}!")
    image.write(output)

    #object_face.write(file: output, acl: :public_read, content_type: sock.content_type)
  end
  #redirect object_face.public_url.to_s
  haml :image
end

