require_relative '../lib/generator'
require_relative '../lib/interpreter'

g = Generator.new
ctx = g.main_ctx

g.bf do
  grapes_quantity = read_byte
  apples_quantity = read_byte
  peaches_quantity = read_byte

  grapes_price = byte(5)
  apples_price = byte(3)
  peaches_price = byte(7)

  grapes_free_quantity = div_with(grapes_quantity, 2)
  dec_with(grapes_quantity, grapes_free_quantity)

  grapes_total = mul(grapes_quantity, grapes_price)
  apples_total = mul(apples_quantity, apples_price)
  peaches_total = mul(peaches_quantity, peaches_price)

  total = add(grapes_total, apples_total)
  total = add(total, peaches_total)
  
  print_decimal(total)
end

puts ctx
  .source
  .chars
  .each_slice(32)
  .to_a
  .map(&:join)
  .join("\n")

out = ""
int = Interpreter.new(ctx.source)
int.execute(out)

puts out

# g.dump
# int.dump
