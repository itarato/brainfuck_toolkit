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
ctx.dec(:d, 2)

ctx.callz(:d) do |c|
  c.inc(:c, 2)
  c.inc(:a)
end

ctx.times(4) do |c|
  c.print(:c)
end

ctx.make_var(:f)
ctx.set(:f, 4)
ctx.set(:c, 'a'.ord)
ctx.make_var(:c1)
ctx.set(:c1, '1'.ord)
ctx.loop_with(:f) do |c|
  c.print(:c)
  c.times(3) do |c2|
    c.print(:c1)
  end
end

ctx.set(:a, 12)
ctx.set(:b, 6)
ctx.mul(:a, :b, :c)
ctx.print(:c)

puts ctx
  .source
  .chars
  .each_slice(32)
  .to_a
  .map(&:join)
  .join("\n")
int = Interpreter.new(ctx.source)
int.execute

# g.dump
# int.dump
