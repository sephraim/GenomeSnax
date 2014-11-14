CONFIG = Hash.new
# Configurations
require_relative File.join('..', 'config', 'constants')
require_relative File.join('..', 'config', 'config')
# Built-in gems
require "rubygems"
require "bundler/setup"
require 'mysql2'
require 'trollop'
# Libraries
require_relative 'error'
require_relative 'print'
require_relative 'genome'
require_relative 'query'
CONFIG.freeze
