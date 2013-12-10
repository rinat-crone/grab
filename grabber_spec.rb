require "rubygems"
require "rspec"
require "./grabber"

describe Grabber do
  describe "init" do
    it "should remove trailing slash from destination" do
      destination = "/tmp"

      grabber = Grabber.new("http://google.com", "#{destination}/")
      grabber.destination.should eq(destination)
    end

    it "should take http and https urls" do
      lambda { Grabber.new("http://google.com", "/tmp") }.should_not raise_error
      lambda { Grabber.new("https://google.com", "/tmp") }.should_not raise_error
    end

    it "should raise an exception if address is invalid" do
      lambda { Grabber.new("ftp://google.com", "/tmp") }.should raise_error
      lambda { Grabber.new("ap://google.chrome", "/tmp") }.should raise_error
    end

    it "should raise an exception if destination is not a folder" do
      lambda { Grabber.new("http://google.com", "/orly") }.should raise_error
    end

    it "should raise an exception if destination is not writable" do
      lambda { Grabber.new("http://google.com", "/usr/bin") }.should raise_error
    end

    it "should set instance variables" do
      address     = "http://google.com"
      destination = "/tmp"
      grabber     = Grabber.new(address, destination)

      grabber.destination.should eq(destination)
      grabber.address.should eq(address)
      grabber.threads.should eq([])
      grabber.images.should eq([])
    end
  end

  describe "download_page" do
    it "should raise an exception if unable to load page" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.address = "some incredible string"

      lambda { grabber.download_page }.should raise_error
    end

    it "should set content variable to nokogiri object" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.download_page

      grabber.content.class.should eq(Nokogiri::HTML::Document)
    end
  end

  describe "parse_page" do
    it "should raise an exception if content variable is not nokogiri object" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.download_page
      grabber.content = "some incredible string"

      lambda { grabber.parse_page }.should raise_error
    end

    it "should parse page and collect images into array" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.download_page
      grabber.parse_page

      grabber.images.size.should_not eq(0)
    end
  end

  describe "download_images" do
    it "should raise an exception if images array is empty" do
      grabber = Grabber.new("http://google.com", "/tmp")
      lambda { grabber.download_images }.should raise_error
    end
  end

  describe "download_image" do
    it "should remove opened file if error occured while image downloading" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.download_image("http://asdfasdfasdfasdasda.com", "/tmp/123.jpg")
      grabber.threads.first.join

      File.exist?("/tmp/123.jpg").should be_false
    end

    it "should download image to destination folder" do
      grabber = Grabber.new("http://google.com", "/tmp")
      grabber.download_image("http://img.artlebedev.ru/;-)/raisin.gif", "/tmp/raisin-test.gif")
      grabber.threads.first.join

      File.exist?("/tmp/raisin-test.gif").should be_true
      File.delete("/tmp/raisin-test.gif")
    end
  end

  describe "process" do
    it "should return true if download complete" do
      Grabber.new("http://google.com", "/tmp").process.should be_true
    end
  end

end