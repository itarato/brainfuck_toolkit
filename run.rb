require_relative 'interpreter'

raise("Missing file") if ARGV.size < 1
raise("Incorrect call, provide a single file input") unless ARGV.size == 1

file_name = ARGV[0]
Interpreter.new(File.open(file_name).read).execute
