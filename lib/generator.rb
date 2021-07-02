require 'forwardable'

class Generator
  attr_reader(:source)

  class Memory
    attr_reader(:vars)
    attr_accessor(:ptr)

    def initialize
      @ptr = 0
      @vars = {}
      @name_counter = 0
    end

    def alloc_byte(name = nil)
      name ||= generate_variable_name
      raise("Duplicated variable #{name}") if @vars.key?(name)
      
      @vars[name] = find_free_segment(1)

      name
    end

    def alloc(size)
      raise("Empty allocation") if size <= 0

      start = find_free_segment(size)
      var_names = size.times.map do |i|
        name = generate_variable_name
        @vars[name] = start + i
        name
      end
      
      Allocation.new(size, var_names)
    end

    def free(name)
      @vars.delete(name)
    end

    def var_pos(name)
      raise("Var does not exist: #{name}") unless @vars.key?(name)
      @vars[name]
    end

    private

    def generate_variable_name
      name = "var#{@name_counter}"
      @name_counter += 1
      name
    end

    def find_free_segment(size)
      occuppied = @vars.values.sort

      start = nil

      if occuppied.empty? || occuppied[0] >= size
        start = 0
      else
        (occuppied.size - 1).times do |i|
          if occuppied[i + 1] - occuppied[i] > size
            start = occuppied[i] + 1
            break
          end
        end

        start ||= occuppied[-1] + 1
      end

      start
    end
  end

  class Allocation
    attr_reader(:size)

    def initialize(size, names)
      @size = size
      @names = names
    end

    def head
      @names[0]
    end

    def [](i)
      raise("Index out of bounds (size=#{size})") if i < 0 || i >= size
      @names[i]
    end
  end

  #
  # Code block context - only single use and always (must be) written immediately.
  #
  class Context
    extend(Forwardable)
    
    #
    # Generated Brainfuck source code.
    #
    attr_reader(:source)

    def_delegators(:@mem, :free)

    def initialize(mem)
      @source = ""
      @mem = mem
    end

    #
    # Create new variable with value.
    #
    def byte(val = 0, name: nil)
      name = mem.alloc_byte(name)
      set(name, val)
      name
    end

    def alloc(size)
      mem.alloc(size)
    end

    def add(lhs, rhs)
      result = byte

      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      bracket(lhs_clone) do
        dec(lhs_clone)
        inc(result)
      end

      bracket(rhs_clone) do
        dec(rhs_clone)
        inc(result)
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def mul(lhs, rhs)
      result = byte

      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      times(lhs_clone) { inc(result, rhs_clone) }

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def eq?(lhs, rhs)
      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      bracket(lhs_clone) do
        dec(lhs_clone)
        dec(rhs_clone)
      end

      result = byte(1)

      bracket(rhs_clone, just_once: true) do
        dec(result)
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def lt?(lhs, rhs)
      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      result = byte

      # Hack to skip ops and return false when eq.
      call_if(-> { eq?(lhs, rhs) }) do
        zero(rhs_clone)
      end

      bracket(rhs_clone) do
        dec(rhs_clone)
        dec(lhs_clone)

        callz(lhs_clone) { inc(result) }
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def gt?(lhs, rhs)
      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      result = byte

      # Hack to skip ops and return false when eq.
      call_if(-> { eq?(lhs, rhs) }) do
        zero(lhs_clone)
      end

      bracket(lhs_clone) do
        dec(rhs_clone)
        dec(lhs_clone)

        callz(rhs_clone) { inc(result) }
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def lte?(lhs, rhs)
      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      result = byte

      # Hack to skip ops and return true when eq.
      call_if(-> { eq?(lhs, rhs) }) do
        zero(rhs_clone)
        inc(result)
      end

      bracket(rhs_clone) do
        dec(rhs_clone)
        dec(lhs_clone)

        callz(lhs_clone) { inc(result) }
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def gte?(lhs, rhs)
      lhs_clone = clone_input(lhs)
      rhs_clone = clone_input(rhs)

      result = byte

      # Hack to skip ops and return true when eq.
      call_if(-> { eq?(lhs, rhs) }) do
        zero(lhs_clone)
        inc(result)
      end

      bracket(lhs_clone) do
        dec(rhs_clone)
        dec(lhs_clone)

        callz(rhs_clone) { inc(result) }
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def mod(dividend, divisor)
      raise("Mod value must be positive non zero") if divisor < 1

      rem = byte
      clone_dividend = clone_input(dividend)

      bracket(clone_dividend) do
        inc(rem)
        call_if(-> { eq?(rem, divisor) }) { zero(rem) }
        dec(clone_dividend)
      end

      free(clone_dividend)

      rem
    end

    def print(v)
      if variable?(v)
        go(v)
        write(".")
      else
        _v = byte(v)
        go(_v)
        write(".")

        free(_v)
      end
    end

    def print_arr(arr)
      raise("Input must be an #{Allocation.name}") unless arr.is_a?(Allocation)

      arr.size.times { |i| print(arr[i]) }
    end

    def print_digit(v)
      v_clone = clone_input(v)

      inc(v_clone, '0'.ord)
      go(v_clone)
      write(".")

      free(v_clone)
    end

    def div(dividend, divisor)
      counter = byte
      clone_dividend = clone_input(dividend)
      divisor_helper = byte
      
      bracket(clone_dividend) do
        dec(clone_dividend)
        inc(divisor_helper)
        
        call_if(-> { eq?(divisor_helper, divisor) }) do
          zero(divisor_helper)
          inc(counter)
        end
      end

      free(clone_dividend)
      free(divisor_helper)

      counter
    end

    def print_decimal(var)
      hundreds = div(var, 100)
      _tens = mod(var, 100)
      tens = div(_tens, 10)
      ones = mod(var, 10)

      hundreds_and_tens = add(hundreds, tens)

      callnz(hundreds) { print_digit(hundreds) }
      callnz(hundreds_and_tens) { print_digit(tens) }
      print_digit(ones)
    end

    def zero(v)
      go(v)
      write("[-]") # Dec until zero
    end

    def inc(v, amount = 1)
      if variable?(amount)
        amount_clone = clone_var(amount)
  
        bracket(amount_clone) do
          inc(v)
          dec(amount_clone)
        end
  
        free(amount_clone)
      else
        go(v)
        write('+' * amount)
      end
    end

    def dec(v, amount = 1)
      if variable?(amount)
        amount_clone = clone_var(amount)
  
        bracket(amount_clone) do
          dec(v)
          dec(amount_clone)
        end
  
        free(amount_clone)
      else
        go(v)
        write('-' * amount)
      end
    end

    def set(v, to)
      if variable?(to)
        zero(v)
        inc(v, to)
      else
        zero(v)
        go(v)

        to = to.ord if char_value?(to)
        write("+" * to)
      end
    end

    def set_arr(arr, value)
      raise("Input must be an #{Allocation.name}") unless arr.is_a?(Allocation)
      raise("Value does not fit to array") unless arr.size >= value.size

      list = case value
      when String then value.chars
      when Array then value
      else raise("Unknown type for array assignment")
      end

      list.each_with_index { |ch, i| set(arr[i], ch) }
    end

    def callz(cond, &blk)
      temp = byte
      inc(temp)

      cond_clone = clone_var(cond)
      bracket(cond_clone, just_once: true) do
        dec(temp)
      end

      bracket(temp, just_once: true) do
        code_with_ctx(&blk)
      end

      free(cond_clone)
      free(temp)
    end

    def callnz(cond, &blk)
      cond_clone = clone_var(cond)

      bracket(cond_clone, just_once: true) do
        code_with_ctx(&blk)
      end

      free(cond_clone)
    end

    def call_if(cond_blk, &blk)
      res = exec(&cond_blk)

      callnz(res, &blk)

      free(res)
    end

    def times(n, from: 0, &blk)
      counter = clone_input(n)

      idx = byte(from)

      bracket(counter) do
        code_with_ctx(idx, &blk)
        dec(counter)
        inc(idx)
      end

      free(idx)
    end

    def debug(message)
      write("@{#{message}}")
    end

    #
    # Executes a block in a new context.
    #
    def exec(&blk)
      ctx = Context.new(mem)
      
      res = ctx.instance_exec(&blk)
      write(ctx.source)

      res
    end

    def read_byte
      out = byte
      go(out)
      write(",")
      out
    end

    private

    attr_reader(:mem)
    
    #
    # Set an active variable (= set mem pointer to var).
    #
    def go(to)
      to = mem.var_pos(to)

      if mem.ptr < to
        write(">" * (to - mem.ptr))
      else
        write("<" * (mem.ptr - to))
      end
      
      mem.ptr = to
    end

    def bracket(var, just_once: false)
      go(var)
      write("[")

      yield

      zero(var) if just_once

      go(var)
      write("]")
    end

    def write(code_text)
      @source << code_text
    end

    def clone_var(var)
      temp = byte
      var_clone = byte

      bracket(var) do
        inc(temp)
        inc(var_clone)
        dec(var)
      end
 
      bracket(temp) do
        inc(var)
        dec(temp)
      end

      free(temp)

      var_clone
    end

    def clone_input(obj)
      variable?(obj) ? clone_var(obj) : byte(char_value?(obj) ? obj.ord : obj.to_i)
    end

    def code_with_ctx(*args, &blk)
      ctx = Context.new(mem)
      ctx.instance_exec(*args, &blk)
      write(ctx.source)
    end

    def variable?(obj)
      obj.is_a?(String) && obj.size > 1
    end

    def char_value?(obj)
      obj.is_a?(String) && obj.size == 1
    end
  end

  attr_reader(:main_ctx)

  def initialize
    @mem = Memory.new
    @main_ctx = Context.new(@mem)
  end

  def bf(&blk)
    @main_ctx.instance_eval(&blk)
    @main_ctx
  end
  
  def dump
    puts 'Memory:'
    @mem.vars.each do |k, v|
      puts "  - #{k} = [#{v}]"
    end
  end
end
