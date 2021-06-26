require "minitest/autorun"

require_relative "../lib/generator"
require_relative "../lib/interpreter"

class TestMeme < Minitest::Test
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
      res = add(:a, :b)
      print(res)
    end
  end

  def test_mul
    assert_produces("H") do
      var(:a, 8)
      var(:b, 9)
      res = mul(:a, :b)
      print(res)
    end
  end

  def test_eq
    assert_produces("1") do
      var(:a, 4)
      var(:b, 4)
      res = eq?(:a, :b)
      print_digit(res)
    end

    assert_produces("0") do
      var(:a, 4)
      var(:b, 8)
      res = eq?(:a, :b)
      print_digit(res)
    end
  end

  def test_eq_to
    assert_produces("1") do
      var(:a, 4)
      res = eq_to?(:a, 4)
      print_digit(res)
    end

    assert_produces("0") do
      var(:a, 4)
      res = eq_to?(:a, 7)
      print_digit(res)
    end
  end

  def test_mod
    assert_produces("2") do
      var(:a, 17)
      res = mod(:a, 5)
      print_digit(res)
    end

    assert_produces("0") do
      var(:a, 15)
      res = mod(:a, 5)
      print_digit(res)
    end
  end

  def test_print
    assert_produces("meme") do
      var(:m, 'm')
      var(:e, 'e')

      print(:m)
      print(:e)
      print(:m)
      print(:e)
    end
  end

  def test_print_digit
    assert_produces("0123456789") do
      times(10) do |i|
        print_digit(i)
      end
    end
  end

  def test_zero
    assert_produces("x0") do
      var(:a, 'x')
      print(:a)

      zero(:a)
      print_digit(:a)
    end
  end

  def test_inc
    assert_produces("B") do
      var(:a, 'A')
      inc(:a)
      print(:a)
    end
  end

  private

  def interpret_code(&blk)
    ctx = Generator.new.bf(&blk)

    output_buffer = ""

    int = Interpreter.new(ctx.source)
    int.execute(output_buffer)

    output_buffer
  end

  def assert_produces(expected, &blk)
    assert_equal(expected, interpret_code(&blk))
  end
end
