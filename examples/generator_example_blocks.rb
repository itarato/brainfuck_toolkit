require_relative 'generator'
require_relative 'interpreter'

g = Generator.new
ctx = g.main_ctx

g.bf do
  var(:a, 42)
  var(:b, 1)
  var(:x, '.')
  
  callz(:b) do
    set(:x, 0)
  end

  print(:a)
  print(:x)
  print(:a)
end

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
