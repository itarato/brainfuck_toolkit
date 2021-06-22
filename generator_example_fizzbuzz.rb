require_relative 'generator'
require_relative 'interpreter'

gen = Generator.new
gen.bf do
  var(:dot, '.'.ord)
  var(:f, 'f')
  var(:i, 'i')
  var(:z, 'z')
  var(:b, 'b')
  var(:u, 'u')
  times(100) do |i|
    print(:dot)
    
    mod3 = mod(i, 3)
    callz(mod3) do
      print(:f)
      print(:i)
      print(:z)
      print(:z)
    end
    mod5 = mod(i, 5)
    callz(mod5) do
      print(:b)
      print(:u)
      print(:z)
      print(:z)
    end
  end
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

int.dump
gen.dump