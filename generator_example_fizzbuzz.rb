require_relative 'generator'
require_relative 'interpreter'

gen = Generator.new
gen.bf do
  # var(:a, '0'.ord)
  # times(10) do |i|
  #   inc_with(:a, :i)
  #   print(:a)
  #   dec_with(:a, :i)
  # end
  var(:b, 3)
  var(:c, 4)
  res = eq?(:b, :c)
end

ctx = gen.main_ctx

puts ctx
  .source
  .chars
  .each_slice(32)
  .to_a
  .map(&:join)
  .join("\n")

int = Interpreter.new(ctx.source)
int.execute

puts int.dump
puts gen.dump