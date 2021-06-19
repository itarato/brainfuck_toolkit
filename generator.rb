require 'securerandom'

class Generator
  attr_reader(:source)

  class Memory
    attr_reader(:vars)
    attr_accessor(:ptr)

    def initialize
      @ptr = 0
      @vars = {}
    end

    def var(name)
      raise("Var name must be symbol") unless name.is_a?(Symbol)
      
      occuppied = @vars.values
      idx = -1
      
      loop do
        idx += 1
        next if occuppied.include?(idx)

        @vars[name] = idx
        return idx
      end
    end

    def free_var(name)
      @vars.delete(name)
    end

    def var_pos(name)
      raise("Var does not exist: #{name}") unless @vars.key?(name)
      @vars[name]
    end
  end

  class Context
    attr_reader(:source)

    def initialize(mem)
      @source = ""
      @mem = mem
    end

    def var(name, val = 0)
      mem.var(name)
      set(name, val) unless val == 0
    end

    def go(to)
      to = mem.var_pos(to)

      if mem.ptr < to
        write(">" * (to - mem.ptr))
      else
        write("<" * (mem.ptr - to))
      end
      
      mem.ptr = to
    end

    def add(a, b, dest)
      if a == b || a == dest || b == dest
        raise("Sources and destination must be different")
      end

      a_clone = clone_var(a)
      b_clone = clone_var(b)

      zero(dest)

      bracket(a_clone) do
        dec(a_clone)
        inc(dest)
      end

      bracket(b_clone) do
        dec(b_clone)
        inc(dest)
      end

      mem.free_var(a_clone)
      mem.free_var(b_clone)
    end

    def mul(a, b, dest)
      if a == b || a == dest || b == dest
        raise("Sources and destination must be different")
      end

      a_clone = clone_var(a)
      b_clone = clone_var(b)

      zero(dest)

      loop_with(a_clone) do
        inc_with(dest, b_clone)
      end

      mem.free_var(a_clone)
      mem.free_var(b_clone)
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

      mem.free_var(lhs_clone)
      mem.free_var(rhs_clone)

      result
    end

    def lt?(lhs, rhs, result)
"""
   2,4,x,_,...
   ^
[- > -                ]

"""                  
    end

    def print(dest)
      go(dest)
      write(".")
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

      mem.free_var(acc)
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

      mem.free_var(acc)
    end

    def set(dest, value)
      zero(dest)
      go(dest)
      write("+" * value)
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

      mem.free_var(cond_clone)
      mem.free_var(temp)
    end

    def callnz(cond, &blk)
      cond_clone = clone_var(cond)

      bracket(cond_clone, just_once: true) do
        code_with_ctx(&blk)
      end

      mem.free_var(cond_clone)
    end

    def times(n, &blk)
      counter = gen_var
      set(counter, n)

      var(:i)

      bracket(counter) do
        code_with_ctx(:i, &blk)
        dec(counter)
        inc(:i)
      end

      mem.free_var(:i)
    end

    def loop_with(var, &blk)
      counter = clone_var(var)

      bracket(counter) do
        code_with_ctx(&blk)
        dec(counter)
      end

      mem.free_var(counter)
    end

    private

    attr_reader(:mem)

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

      mem.free_var(temp)

      var_clone
    end

    def gen_var
      name = SecureRandom.hex(12).to_sym
      var(name)
      name
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
