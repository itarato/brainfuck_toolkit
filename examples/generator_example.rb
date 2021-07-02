require_relative '../lib/generator'
require_relative '../lib/interpreter'
require_relative '../scripts/pretty_printer'

g = Generator.new
ctx = g.main_ctx

g.bf do
  grapes_quantity = read_byte
  apples_quantity = read_byte
  peaches_quantity = read_byte

  grapes_price = byte(5)
  apples_price = byte(3)
  peaches_price = byte(7)

  grapes_free_quantity = div(grapes_quantity, 2)
  dec_with(grapes_quantity, grapes_free_quantity)

  grapes_total = mul(grapes_quantity, grapes_price)
  apples_total = mul(apples_quantity, apples_price)
  peaches_total = mul(peaches_quantity, peaches_price)

  apples_discount_min = byte(2)
  callnz(gte?(apples_quantity, apples_discount_min)) do
    apples_total = div(apples_total, 5)
    apples_total = mul(apples_total, byte(4))
  end

  total = add(grapes_total, apples_total)
  total = add(total, peaches_total)
  
  print_decimal(total)
end

PrettyPrinter.pretty_print(ctx.source)

out = ""
int = Interpreter.new(ctx.source)
int.execute(out)

puts out

# g.dump
# int.dump
