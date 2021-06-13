require_relative 'generator'
require_relative 'interpreter'

ctx = Generator.new.main_ctx

ctx.make_var(:a)
ctx.make_var(:b)
ctx.make_var(:c)

ctx.set(:a, 22)
ctx.set(:b, 20)
ctx.add(:a, :b, :c)
ctx.print(:c)

puts ctx.source
Interpreter.execute(ctx.source)
