##
# The purpose of this initializer is to set up global variables that reference common functions (logging, etc.) with configuration
# from their associated properties file in the config/props directory
#
require 'erb'

module PropLoader
  extend self
  @props = {}

  class << self
    attr_accessor :props
  end

  def self.load_prop_files(*dirs)
    dirs.each do |dir|
      # iterate over all of the .properties files in the directory
      Dir.glob("#{dir}/*.properties*") do |file|
        key_prefix = File.basename(file).split(".")[0].upcase

        if File.extname(file).eql?('.erb')
          props = self.read_props_from_erb(file, key_prefix)
        else
          # read the file line by line stripping out properties
          props = read_prop_file(file, key_prefix)
        end
        @props.merge!(props)
      end
    end
  end

  private
  def self.read_prop_file(file, key_prefix)
    ret = {}

    File.readlines(file).each do |line|
      r = read_prop_line(line, key_prefix)
      ret.merge!(r)
    end
    ret
  end

  def self.read_props_from_erb(erb, key_prefix)
    props = ERB.new(File.open(erb, 'r') { |file| file.read }).result
    properties = {}
    prop_array = props.split("\n")
    prop_array.each do |line|
      properties.merge!(read_prop_line(line, key_prefix))
    end
    properties
  end

  def self.read_prop_line(line, key_prefix)
    ret = {}
    line.strip!
    if line =~ /^[a-z].*=.*$/
      kv = line.split('=')
      ret["#{key_prefix}.#{kv[0]}"] = kv[1]
    end
    ret
  end
end

PropLoader.load_prop_files('./config/props')
$PROPS = PropLoader.props.freeze
