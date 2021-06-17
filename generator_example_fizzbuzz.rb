require_relative 'generator'
require_relative 'interpreter'

ctx = Generator.new.bf do
  var(:a, '0'.ord)
  times(10) do |i|
    inc_with(:a, :i)
    print(:a)
    dec_with(:a, :i)
  end
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
