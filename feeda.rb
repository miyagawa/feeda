#!/usr/bin/env ruby
require 'feedzirra'
require 'pathname'
require 'digest/sha1'
require 'thor'
require 'pry'

module Feeda
  class Feed
    attr_accessor :feed

    def initialize(url)
      @url = url
      @path = cache_path
      @first = false
    end

    def cache_path
      base = Pathname.new(ENV['FEEDA_HOME'] || "#{Dir.home}/.feeda")
      base.mkdir unless base.exist?
      base + digest
    end

    def digest
      Digest::SHA1.hexdigest @url
    end

    def update(all)
      @feed = all ? fetch : (restore || fetch)
    end

    def restore
      if @path.exist?
        @feed = Marshal.load(File.read(@path))
      end
    end

    def save
      File.open(@path, 'w') do |file|
        file.puts Marshal.dump(@feed)
      end
    end

    def first?
      @first
    end

    def fetch
      @first = true
      Feedzirra::Feed.fetch_and_parse(@url)
    end

    def new_entries
      first? ? @feed.entries : @feed.new_entries
    end
  end

  class CLI < Thor
    desc "update URL ACTION", "update feed and run action for each new entry"
    option :all, :type => :boolean
    def update(url, action=nil)
      remote = Feed.new(url)
      remote.update(options[:all])
      if action
        feed = remote.feed
        remote.new_entries.each do |entry|
          entry.instance_eval(action)
        end
      end
    end
  end

  module PatchFeedzirra
    def self.included(base)
      base.class_eval do
        element :enclosure, :value => :length, :as => :enclosure_length
        element :enclosure, :value => :type, :as => :enclosure_type
        element :enclosure, :value => :url, :as => :enclosure_url
      end
    end
  end
  Feedzirra::Parser::RSSEntry.send :include, PatchFeedzirra
end

Feeda::CLI.start(ARGV)
