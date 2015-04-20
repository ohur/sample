#!/usr/bin/env ruby
# tested with ruby v 1.8 and 2.0

require 'rubygems'  # required for ruby v 1.8
require 'gchart'
require 'logger'
require 'optparse'

############################################
# This script requires two arguments
# The first arguement is the root directory
# The second arguement is the regular expression, in quote
# The script will use the regular expression to match
# any file in the root directory and its subdirectory
# The output data is in array, and in graphic form
########################################################

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: regex_subdir_graph.rb --root_dir . --regexp '/log$/i'"

  options[:root_dir] = nil
  opts.on( '--root_dir ROOT_DIR', 'Root Directory' ) do |root_dir|
    options[:root_dir] = root_dir
  end
  options[:regexp] = nil
  opts.on( '--regexp REGEXP', String, 'Regular Expression, needed to be in quote' ) do |regexp|
    options[:regexp] = regexp
  end

  opts.on( '-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

optparse.parse!

root_dir = options[:root_dir]
unless File.directory?(root_dir)
  abort "Input #{root_dir} is not a valid directory"
end

options[:regexp] =~ /^\/(.*)\/(\w*)$/
pattern = $1
modifier = $2


if modifier.empty?
  regexp = Regexp.new pattern
elsif modifier.eql?"i"
  regexp = Regexp.new(pattern, Regexp::IGNORECASE)
end

original_dir = Dir.pwd

Dir.chdir("#{root_dir}")

log = Logger.new("#{original_dir}/regex_subdir_graph.txt")
log.debug "Looking for a match to the file name with /#{pattern}/#{modifier} "\
          "in the directory, #{root_dir}, and its sub directories."
directories = Dir.glob("**/")
directories.push("#{Dir.pwd}")
results_hash = {}

directories.each do |directory|
  counter = 0
  begin

    Dir.foreach(directory) do |file_name|
      if file_name =~ regexp
        counter += 1
        results_hash["#{directory}"] = counter
      end
    end
  rescue Errno::EACCES => e
    # in case if permission is denied in the subdir
    log.info e.message
    log.info e.backtrace
  rescue Errno::ENOENT => e
    log.info e.message
    log.info e.backtrace
  end
end

if results_hash.empty?
  msg = "No match found"
  log.info "#{msg}"
  abort "#{msg}"
end

results_array = []
results_hash.each do |key, value|
  # store the key value pair in an array as required
  element = "#{key}" + ": " + "#{value}, "
  results_array.push(element)
end

log.info "==========================="
log.info "Output the data result in array: #{results_array}"
log.info "==========================="

# Ouput in graph

file_matched_in_subdir = results_hash.values
x_axis_instances = file_matched_in_subdir.length
y_max_value = file_matched_in_subdir.max
bar_width = (400/x_axis_instances).to_i

if bar_width < 1
  msg = "Match found in too many subdirectories.  Unable to output "\
        "in gchart"
  log.info "#{msg}"
  log.info "\n******************************\n"
  abort "#{msg}"
end

# Set the graph size to 700x400.  Image too big would cause gchart
# to fail.
bar_chart = Gchart.new(
            :type => 'bar',
            :size => '700x400',
            :bar_colors => "000000",
            :bar_width_and_spacing => ["#{bar_width}",1],
            :title => "Number of Files Matched",
            :bg => 'EFEFEF',
            :legend => ['Subdirectories'],
            :legend_position => 'bottom',
            :data => file_matched_in_subdir,
            :axis_with_labels => 'x,y',
            :axis_labels =>  [nil, [0,"#{y_max_value}"]],
            :filename => "#{original_dir}/"+"#{Time.now}.png")

bar_chart.file
log.info "Graphic file has been generated"
Dir.chdir("#{original_dir}")
log.info "\n******************************\n"


