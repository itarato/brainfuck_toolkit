require_relative 'generator'
require_relative 'interpreter'

g = Generator.new

g.make_var(:a)
g.make_var(:b)
g.make_var(:c)

g.set(:a, 22)
g.set(:b, 20)
g.add(:a, :b, :c)
g.print(:c)

puts g.source
Interpreter.execute(g.source)
