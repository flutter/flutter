#!/usr/bin/env ruby

require 'optparse'
require 'pathname'
require 'webrick/htmlutils'

$LOAD_PATH << Pathname.new(__FILE__).dirname.realpath.to_s

require 'PrettyPatch'

BACKTRACE_SEPARATOR = "\n\tfrom "

options = { :html_exceptions => false }
OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($0)} [options] [patch-file]"

    opts.separator ""

    opts.on("--html-exceptions", "Print exceptions to stdout as HTML") { |h| options[:html_exceptions] = h }
end.parse!

patch_data = nil
if ARGV.length == 0 || ARGV[0] == '-' then
    patch_data = $stdin.read
else
    File.open(ARGV[0]) { |file| patch_data = file.read }
end

begin
    puts PrettyPatch.prettify(patch_data)
rescue => exception
    raise unless options[:html_exceptions]

    backtrace = exception.backtrace
    backtrace[0] += ": " + exception + " (" + exception.class.to_s + ")"
    print "<pre>\n", WEBrick::HTMLUtils::escape(backtrace.join(BACKTRACE_SEPARATOR)), "\n</pre>\n"
end
