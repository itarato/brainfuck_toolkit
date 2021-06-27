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

    def add(a, b)
      raise("Sources and destination must be different") if a == b

      result = gen_var

      a_clone = clone_var(a)
      b_clone = clone_var(b)

      zero(result)

      bracket(a_clone) do
        dec(a_clone)
        inc(result)
      end

      bracket(b_clone) do
        dec(b_clone)
        inc(result)
      end

      free(a_clone)
      free(b_clone)

      result
    end

    def mul(a, b)
      raise("Sources and destination must be different") if a == b

      result = gen_var

      a_clone = clone_var(a)
      b_clone = clone_var(b)

      zero(result)

      loop_with(a_clone) do
        inc_with(result, b_clone)
      end

      free(a_clone)
      free(b_clone)

      result
    end

    def eq?(lhs, rhs)
      lhs_clone = clone_var(lhs)
      rhs_clone = clone_var(rhs)

      bracket(lhs_clone) do
        dec(lhs_clone)
        dec(rhs_clone)
      end

      result = gen_var
      set(result, 1)

      bracket(rhs_clone, just_once: true) do
        dec(result)
      end

      free(lhs_clone)
      free(rhs_clone)

      result
    end

    def eq_to?(v_num, value)
      v_value = gen_var(value)

      result = eq?(v_num, v_value)

      free(v_value)

      result
    end

    def mod(v_num, value)
      raise("Mod value must be positive non zero") if value < 1

      rem = gen_var
      clone_v_num = clone_var(v_num)

      bracket(clone_v_num) do
        inc(rem)
        calleq_to(rem, value) { zero(rem) }
        dec(clone_v_num)
      end

      free(clone_v_num)

      rem
    end

    def print(dest)
      go(dest)
      write(".")
    end

    def print_arr(arr)
      raise("Input must be an #{Allocation.name}") unless arr.is_a?(Allocation)

      arr.size.times do |i|
        print(arr[i])
      end
    end

    def print_digit(dest)
      digit = clone_var(dest)

      inc(digit, '0'.ord)
      go(digit)
      write(".")
      free(digit)
    end

    def zero(dest)
      go(dest)
      write("[-]") # Dec until zero
    end

    def inc(dest, value = 1)
      go(dest)
      write('+' * value)
    end

    def inc_with(dest, var)
      acc = clone_var(var)

      bracket(acc) do
        inc(dest)
        dec(acc)
      end

      free(acc)
    end

    def dec(dest, value = 1)
      go(dest)
      write('-' * value)
    end

    def dec_with(dest, var)
      acc = clone_var(var)

      bracket(acc) do
        dec(dest)
        dec(acc)
      end

      free(acc)
    end

    def set(dest, value)
      zero(dest)
      go(dest)

      value = value.ord if value.is_a?(String)
      write("+" * value)
    end

    def set_arr(arr, value)
      raise("Input must be an #{Allocation.name}") unless arr.is_a?(Allocation)
      raise("Value does not fit to array") unless arr.size >= value.size

      value.chars.each_with_index do |ch, i|
        set(arr[i], ch)
      end
    end

    def callz(cond, &blk)
      temp = gen_var
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

    def calleq(lhs, rhs, &blk)
      eq_res = eq?(lhs, rhs)

      bracket(eq_res, just_once: true) do
        code_with_ctx(&blk)
      end

      free(eq_res)
    end

    def calleq_to(v_num, value, &blk)
      eq_res = eq_to?(v_num, value)

      bracket(eq_res, just_once: true) do
        code_with_ctx(&blk)
      end

      free(eq_res)
    end

    def times(n, &blk)
      counter = gen_var
      set(counter, n)

      idx = gen_var

      bracket(counter) do
        code_with_ctx(idx, &blk)
        dec(counter)
        inc(idx)
      end

      free(idx)
    end

    def loop_with(var, &blk)
      counter = clone_var(var)

      bracket(counter) do
        code_with_ctx(&blk)
        dec(counter)
      end

      free(counter)
    end

    def debug(message)
      write("@{#{message}}")
    end

    #
    # Executes a block in a new context.
    #
    def exec(&blk)
      ctx = Context.new(mem)
      ctx.instance_exec(&blk)
      write(ctx.source)
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
      temp = gen_var
      var_clone = gen_var

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

    def gen_var(value = 0)
      byte(value)
    end

    def code_with_ctx(*args, &blk)
      ctx = Context.new(mem)
      ctx.instance_exec(*args, &blk)
      write(ctx.source)
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
