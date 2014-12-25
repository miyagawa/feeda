#!/usr/bin/env ruby
require 'feedzirra'
require 'pathname'
require 'digest/sha1'
require 'thor'
require 'htmlentities'

module Feeda
  class Feed
    attr_accessor :feed, :new_entries

    def initialize(url)
      @url = url
      @path = cache_path
      @first = true
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
      @feed = Feedzirra::Feed.fetch_and_parse(@url)
      @new_entries = @feed.entries
      if @path.exist? && !all
        @first = false
        cache = Marshal.load(File.read(@path))
        # don't use select! because that will break the cache
        @new_entries = @new_entries.select {|entry| entry.published > cache.entries.first.published }
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
  end

  class CLI < Thor
    desc "update URL", "update feed and run action for each new entry"
    method_option :eval, :aliases => "-e"
    method_options :first => :numeric
    method_options :all => :boolean
    def update(url)
      remote = Feed.new(url)
      remote.update(options[:all])
      if options[:eval]
        feed = remote.feed
        entries = options[:first] ? remote.new_entries.first(options[:first]) : remote.new_entries
        entries.each do |entry|
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
        element :enclosure, :value => :url, :as => :enclosure_url_original

        def enclosure_url
          HTMLEntities.new.decode(enclosure_url_original)
        end
      end
    end
  end
  Feedzirra::Parser::RSSEntry.send :include, PatchFeedzirra
end

Feeda::CLI.start(ARGV)
