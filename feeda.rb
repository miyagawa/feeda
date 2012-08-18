#!/usr/bin/env ruby
require 'feedzirra'
require 'pathname'
require 'digest/sha1'
require 'thor'

module Feeda
  class Feed
    attr_accessor :feed, :new_entries

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
      all ? fetch : (restore_and_update || fetch)
    end

    def restore_and_update
      if @path.exist?
        old = Marshal.load(File.read(@path))
        @feed = Feedzirra::Feed.fetch_and_parse(@url)
        @new_entries = @feed.entries.select {|entry| entry.published > old.entries.first.published }
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
      @feed = Feedzirra::Feed.fetch_and_parse(@url)
      @new_entries = @feed.entries
    end
  end

  class CLI < Thor
    desc "update URL", "update feed and run action for each new entry"
    option :eval, :aliases => "-e"
    option :all, :type => :boolean
    def update(url)
      remote = Feed.new(url)
      remote.update(options[:all])
      if options[:eval]
        feed = remote.feed
        remote.new_entries.each do |entry|
          entry.instance_eval(options[:eval])
        end
      end
      remote.save
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
