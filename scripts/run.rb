require_relative '../lib/interpreter'

raise("Missing file") if ARGV.size < 1
raise("Incorrect call, provide a single file input") unless ARGV.size == 1

file_name = ARGV[0]

puts "#{'-' * 16} SCREEN #{'-' * 16}"
Interpreter.new(File.open(file_name).read).execute
puts "\n#{'-' * 16}  DONE  #{'-' * 16}"
