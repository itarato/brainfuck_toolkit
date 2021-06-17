require_relative 'generator'
require_relative 'interpreter'

g = Generator.new
ctx = g.main_ctx

g.code do
  make_var(:a)
  make_var(:b)
  make_var(:c)

  set(:a, 20)
  set(:b, 20)
  add(:a, :b, :c)
  print(:c)

  make_var(:d)
  inc(:d, 2)
  dec(:d, 2)

  callz(:d) do
    inc(:c, 2)
    inc(:a)
  end

  times(4) do
    print(:c)
  end

  make_var(:f)
  set(:f, 4)
  set(:c, 'a'.ord)
  make_var(:c1)
  set(:c1, '1'.ord)
  loop_with(:f) do
    print(:c)
    times(3) do
      print(:c1)
    end
  end

  """
  while({ |c| })
  """

  set(:a, 13)

  set(:b, 6)
  mul(:a, :b, :c)
  print(:c)
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
