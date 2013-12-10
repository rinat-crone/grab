require './nokogiri/lib/nokogiri'
require 'open-uri'

class Grabber
  attr_accessor :destination, :address, :content, :threads, :images

  def initialize(address, destination)
    destination = destination[0..-2] if destination.end_with?("/")

    raise "Invalid page address given" if address.match(URI::regexp(%w(http https))).nil?
    raise "#{destination} is not a folder" unless File.directory?(destination)
    raise "#{destination} is not writable" unless File.writable?(destination)

    @destination  = destination
    @address      = address
    @threads      = []
    @images       = []
  end

  def process
    download_page
    parse_page
    download_images
    threads.each{ |t| t.join }

    true
  end

  def download_page
    begin
      page = open(address)
    rescue
      raise "Requested page not exists"
    end

    self.content = Nokogiri::HTML(page)
  end

  def parse_page
    raise "Content is not Nokogiri::HTML::Document" if content.class != Nokogiri::HTML::Document

    content.traverse do |el|
      [el[:src]].grep(/\.(gif|jpg|jpeg|png)$/i).map{ |l| URI.join(address, l).to_s }.each do |link|
        self.images << link
      end
    end
  end

  def download_images
    raise "Nothing to download" if images.size == 0

    images.each{ |i| download_image(i, "#{destination}/#{File.basename(i)}") }
  end

  def download_image(link, local_file)
    self.threads << Thread.new(link) do |link|
      begin
        File.open(local_file, 'wb') do |file|
          begin
            file << open(link, 'rb').read
          rescue SocketError => e
            File.delete(local_file)
          end

          file.close
        end
      rescue Errno::EMFILE => e
        retry
      end
    end
  end
end
