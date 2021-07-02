require_relative '../lib/generator'
require_relative '../lib/interpreter'

gen = Generator.new
gen.bf do
  is_nothing = byte
  fizz = alloc(4, 'fizz')
  buzz = alloc(4, 'buzz')
  nl =  byte("\n")

  times(100) do |idx|
    set(is_nothing, 1)

    callz(mod(idx, 3)) do
      print_arr(fizz)
      zero(is_nothing)
    end

    callz(mod(idx, 5)) do
      print_arr(buzz)
      zero(is_nothing)
    end

    callnz(is_nothing) { print_decimal(idx) }
    print(nl)
  end
end

ctx = gen.main_ctx

puts ctx
  .source
  .chars
  .each_slice(64)
  .to_a
  .map(&:join)
  .join("\n")

screen = ""

int = Interpreter.new(ctx.source)
int.execute(screen)

puts(screen)

int.dump
gen.dump
