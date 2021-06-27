require "minitest/autorun"

require_relative "../lib/generator"
require_relative "../lib/interpreter"

class TestMeme < Minitest::Test
  def test_variables
    assert_produces("*\u0000x") do
      x = byte(42)
      y = byte
      z = byte('x')

      print(x)
      print(y)
      print(z)
    end
  end

  def test_add
    assert_produces("F") do
      a = byte('A')
      b = byte(5)
      res = add(a, b)
      print(res)
    end
  end

  def test_mul
    assert_produces("H") do
      a = byte(8)
      b = byte(9)
      res = mul(a, b)
      print(res)
    end
  end

  def test_eq
    assert_produces("1") do
      a = byte(4)
      b = byte(4)
      res = eq?(a, b)
      print_digit(res)
    end

    assert_produces("0") do
      a = byte(4)
      b = byte(8)
      res = eq?(a, b)
      print_digit(res)
    end
  end

  def test_eq_to
    assert_produces("1") do
      a = byte(4)
      res = eq_to?(a, 4)
      print_digit(res)
    end

    assert_produces("0") do
      a = byte(4)
      res = eq_to?(a, 7)
      print_digit(res)
    end
  end

  def test_mod
    assert_produces("2") do
      a = byte(17)
      res = mod(a, 5)
      print_digit(res)
    end

    assert_produces("0") do
      a = byte(15)
      res = mod(a, 5)
      print_digit(res)
    end
  end

  def test_print
    assert_produces("meme") do
      m = byte('m')
      e = byte('e')

      print(m)
      print(e)
      print(m)
      print(e)
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
      a = byte('x')
      print(a)

      zero(a)
      print_digit(a)
    end
  end

  def test_alloc
    assert_produces("why") do
      arr = alloc(3)
      set_arr(arr, "why")
      print_arr(arr)
    end
  end

  def test_inc
    assert_produces("B") do
      a = byte('A')
      inc(a)
      print(a)
    end
  end

  def test_inc_with
    assert_produces("R") do
      a = byte('P')
      b = byte(2)
      inc_with(a, b)
      print(a)
    end
  end

  def test_dec
    assert_produces("A") do
      a = byte('B')
      dec(a)
      print(a)
    end
  end

  def test_dec_with
    assert_produces("P") do
      a = byte('R')
      b = byte(2)
      dec_with(a, b)
      print(a)
    end
  end

  def test_set
    assert_produces("\u0000x") do
      a = byte
      print(a)
      set(a, 'x')
      print(a)
    end
  end

  def test_callz
    assert_produces("x") do
      a = byte
      b = byte('x')
      callz(a) do
        print(b)
      end
    end

    assert_produces("") do
      a = byte(1)
      b = byte('x')
      callz(a) do
        print(b)
      end
    end
  end

  def test_callnz
    assert_produces("") do
      a = byte
      b = byte('x')
      callnz(a) do
        print(b)
      end
    end

    assert_produces("x") do
      a = byte(1)
      b = byte('x')
      callnz(a) do
        print(b)
      end
    end
  end

  def test_calleq
    assert_produces("x") do
      a = byte(5)
      b = byte(5)
      c = byte('x')
      calleq(a, b) do
        print(c)
      end
    end

    assert_produces("") do
      a = byte(5)
      b = byte(7)
      c = byte('x')
      calleq(a, b) do
        print(c)
      end
    end
  end

  def test_calleq_to
    assert_produces("x") do
      a = byte(5)
      c = byte('x')
      calleq_to(a, 5) do
        print(c)
      end
    end

    assert_produces("") do
      a = byte(5)
      c = byte('x')
      calleq_to(a, 7) do
        print(c)
      end
    end
  end

  def test_times
    assert_equal("0123") do
      times(4) do |i|
        print_digit(i)
      end
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
