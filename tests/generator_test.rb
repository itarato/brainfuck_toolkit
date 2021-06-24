require "minitest/autorun"

require_relative "../lib/generator"
require_relative "../lib/interpreter"

class TestMeme < Minitest::Test
  def setup
    @gen = Generator.new
  end

  def test_variables
    assert_produces("*\u0000x") do
      var(:x, 42)
      var(:y)
      var(:z, 'x')

      print(:x)
      print(:y)
      print(:z)
    end
  end

  def test_bad_var_name
    assert_raises do
      interpret_code do
        var("notsymbol")
      end
    end
  end

  def test_add
    assert_produces("F") do
      var(:a, 'A')
      var(:b, 5)
      var(:res)
      add(:a, :b, :res)
      print(:res)
    end
  end

  def test_mul
    assert_produces("H") do
      var(:a, 8)
      var(:b, 9)
      var(:res)
      mul(:a, :b, :res)
      print(:res)
    end
  end

  private

  def interpret_code(&blk)
    ctx = @gen.bf(&blk)

    output_buffer = ""

    int = Interpreter.new(ctx.source)
    int.execute(output_buffer)

    output_buffer
  end

  def assert_produces(expected, &blk)
    assert_equal(expected, interpret_code(&blk))
  end
end
