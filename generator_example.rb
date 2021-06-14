require_relative 'generator'
require_relative 'interpreter'

g = Generator.new
ctx = g.main_ctx

ctx.make_var(:a)
ctx.make_var(:b)
ctx.make_var(:c)

ctx.set(:a, 20)
ctx.set(:b, 20)
ctx.add(:a, :b, :c)
ctx.print(:c)

ctx.make_var(:d)
ctx.inc(:d, 2)
# ctx.dec(:d, 2)

ctx.callnz(:d) do |c|
  c.inc(:c, 2)
  c.make_var(:f)
  c.inc(:a)
end

ctx.print(:c)

puts ctx.source
int = Interpreter.new(ctx.source)
int.execute

# g.dump
# int.dump
