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

    assert_produces("F") do
      a = byte('A')
      res = add(5, a)
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
    
    assert_produces("H") do
      b = byte(8)
      res = mul(9, b)
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

    assert_produces("1") do
      a = byte(4)
      res = eq?(a, 4)
      print_digit(res)
    end

    assert_produces("0") do
      a = byte(4)
      res = eq?(a, 7)
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

    assert_produces("hi") do
      print('h')
      print('i')
    end
  end

  def test_print_digit
    assert_produces("0123456789") do
      times(10) do |i|
        print_digit(i)
      end
    end

    assert_produces("7") do
      print_digit(7)
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

  def test_set_arr
    assert_produces("CEC") do
      arr = alloc(3)
      set_arr(arr, [67, 69, 67])
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

  def test_inc
    assert_produces("R") do
      a = byte('P')
      b = byte(2)
      inc(a, b)
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

  def test_dec
    assert_produces("P") do
      a = byte('R')
      b = byte(2)
      dec(a, b)
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

    assert_produces("*") do
      a = byte('*')
      b = byte(7)
      set(b, a)
      print(b)
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
    assert_produces("x") do
      a = byte(5)
      c = byte('x')
      calleq(a, 5) do
        print(c)
      end
    end

    assert_produces("") do
      a = byte(5)
      c = byte('x')
      calleq(a, 7) do
        print(c)
      end
    end
  end
  def test_times
    assert_produces("0123") do
      times(4) do |i|
        print_digit(i)
      end
    end
  end

  def test_loop_with
    assert_produces("****") do
      i = byte(4)
      a = byte('*')
      loop_with(i) do
        print(a)
      end
    end
  end

  def test_exec
    assert_produces("xoxo") do
      a = byte('x')
      blk = -> {
        b = byte('o')
        print(b)
      }

      print(a)
      exec(&blk)
      print(a)
      exec(&blk)
    end
  end

  def test_conditional_blocks_do_not_mess_up_memory_location
    assert_produces("xxy") do
      a = byte('x')
      b = byte('y')
      c = byte

      callz(c) { print(a) } # -> x
      inc(c)
      callz(c) { print(b) } # -> nothing

      print(a) # -> x
      print(b) # -> y
    end
  end

  def test_div
    assert_produces("6") do
      dividend = byte(125)
      res = div(dividend, 20)
      print_digit(res)
    end

    assert_produces("6") do
      dividend = byte(120)
      res = div(dividend, 20)
      print_digit(res)
    end
    
    assert_produces("5") do
      dividend = byte(119)
      res = div(dividend, 20)
      print_digit(res)
    end

    assert_produces("0") do
      dividend = byte(19)
      res = div(dividend, 20)
      print_digit(res)
    end

    assert_produces("0") do
      dividend = byte(0)
      res = div(dividend, 20)
      print_digit(res)
    end
  end

  def test_print_decimal
    assert_produces("123") do
      x = byte(123)
      print_decimal(x)
    end

    assert_produces("23") do
      x = byte(23)
      print_decimal(x)
    end

    assert_produces("203") do
      x = byte(203)
      print_decimal(x)
    end

    assert_produces("200") do
      x = byte(200)
      print_decimal(x)
    end

    assert_produces("30") do
      x = byte(30)
      print_decimal(x)
    end

    assert_produces("5") do
      x = byte(5)
      print_decimal(x)
    end

    assert_produces("0") do
      x = byte
      print_decimal(x)
    end
  end

  def test_lt
    assert_produces("1") do
      x = byte(32)
      y = byte(33)
      print_digit(lt?(x, y))
    end

    assert_produces("0") do
      x = byte(32)
      y = byte(32)
      print_digit(lt?(x, y))
    end
    
    assert_produces("0") do
      x = byte(32)
      y = byte(30)
      print_digit(lt?(x, y))
    end
  end

  def test_gt
    assert_produces("0") do
      x = byte(32)
      y = byte(33)
      print_digit(gt?(x, y))
    end

    assert_produces("0") do
      x = byte(32)
      y = byte(32)
      print_digit(gt?(x, y))
    end
    
    assert_produces("1") do
      x = byte(32)
      y = byte(30)
      print_digit(gt?(x, y))
    end
  end

  def test_lte
    assert_produces("1") do
      x = byte(32)
      y = byte(33)
      print_digit(lte?(x, y))
    end

    assert_produces("1") do
      x = byte(32)
      y = byte(32)
      print_digit(lte?(x, y))
    end
    
    assert_produces("0") do
      x = byte(32)
      y = byte(30)
      print_digit(lte?(x, y))
    end
  end

  def test_gte
    assert_produces("0") do
      x = byte(32)
      y = byte(33)
      print_digit(gte?(x, y))
    end

    assert_produces("1") do
      x = byte(32)
      y = byte(32)
      print_digit(gte?(x, y))
    end
    
    assert_produces("1") do
      x = byte(32)
      y = byte(30)
      print_digit(gte?(x, y))
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
