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

    def make_var(name)
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

    def make_var(name)
      mem.make_var(name)
    end

    def go(to)
      to = mem.var_pos(to)

      if mem.ptr < to
        code(">" * (to - mem.ptr))
      else
        code("<" * (mem.ptr - to))
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

    def print(dest)
      go(dest)
      code(".")
    end

    def zero(dest)
      go(dest)
      code("[-]") # Dec until zero
    end

    def inc(dest, value = 1)
      go(dest)
      code('+' * value)
    end

    def dec(dest, value = 1)
      go(dest)
      code('-' * value)
    end

    def set(dest, value)
      zero(dest)
      go(dest)
      code("+" * value)
    end

    def callz(cond)
      temp = gen_var
      inc(temp)

      cond_clone = clone_var(cond)
      bracket(cond_clone, just_once: true) do
        dec(temp)
      end

      bracket(temp, just_once: true) do
        ctx = spawn_ctx
        yield(ctx)
        code(ctx.source) # Execute context
      end

      mem.free_var(cond_clone)
      mem.free_var(temp)
    end

    def callnz(cond)
      cond_clone = clone_var(cond)

      bracket(cond_clone, just_once: true) do
        ctx = spawn_ctx
        yield(ctx)
        code(ctx.source) # Execute context
      end

      mem.free_var(cond_clone)
    end

    def times(n)
      counter = gen_var
      set(counter, n)

      bracket(counter) do
        ctx = spawn_ctx
        yield(ctx)
        code(ctx.source)

        dec(counter)
      end
    end

    def loop_with(var)
      counter = clone_var(var)

      bracket(counter) do
        ctx = spawn_ctx
        yield(ctx)
        code(ctx.source)

        dec(counter)
      end

      mem.free_var(counter)
    end

    private

    attr_reader(:mem)

    def bracket(var, just_once: false)
      go(var)
      code("[")

      yield

      zero(var) if just_once

      go(var)
      code("]")
    end

    def code(code_text)
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
      make_var(name)
      name
    end

    def spawn_ctx
      Context.new(mem)
    end
  end

  attr_reader(:main_ctx)

  def initialize
    @mem = Memory.new
    @main_ctx = Context.new(@mem)
  end
  
  def dump
    puts 'Memory:'
    @mem.vars.each do |k, v|
      puts "  - #{k} = [#{v}]"
    end
  end
end
