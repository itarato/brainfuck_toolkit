class Generator
  attr_reader(:source)

  class Memory
    attr_reader(:vars)
    attr_accessor(:ptr)

    def initialize
      @ptr = 0
      @vars = {}
    end

    #
    # @param name - Symbol, name of var
    # @returns Integer - Index of free space
    #
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

    def var_pos(name)
      raise("Var does not exist: #{name}") unless @vars.key?(name)
      @vars[name]
    end

    def free_var(name)
      @vars.delete(name)
    end
  end

  def initialize
    @source = ""
    @mem = Memory.new
  end

  def make_var(name)
    @mem.make_var(name)
  end

  #
  # Does not verify destination state!
  #
  def add(v_a, v_b, v_dest)
    source_a = @mem.var_pos(v_a)
    source_b = @mem.var_pos(v_b)
    dest = @mem.var_pos(v_dest)

    if source_a == source_b || source_b == dest || source_a == dest
      raise("Sources and destination must be different")
    end

    # Zero dest
    zero(v_dest)

    # Increment dest by first num
    move_mem_p(source_a) # Go to first num
    code("[") # Start loop
    code("-") # Dec source-a
    move_mem_p(dest) # Move to dest
    code("+") # Inc dest
    move_mem_p(source_a) # Move to source a
    code("]") # Loop end (at source a)

    # Increment dest by second num
    move_mem_p(source_b) # Go to second num
    code("[") # Start loop
    code("-") # Dec source-b
    move_mem_p(dest) # Move to dest
    code("+") # Inc dest
    move_mem_p(source_b) # Move to source a
    code("]") # Loop end (at source b)
  end

  def print(v_dest)
    dest = @mem.var_pos(v_dest)

    move_mem_p(dest)
    code(".")
  end

  def zero(v_dest)
    dest = @mem.var_pos(v_dest)

    move_mem_p(dest)
    code("[-]") # Dec until zero
  end

  def set(v_dest, value)
    dest = @mem.var_pos(v_dest)

    zero(v_dest)
    move_mem_p(dest)
    code("+" * value)
  end

  private
  
  def move_mem_p(to)
    if @mem.ptr < to
      code(">" * (to - @mem.ptr))
    else
      code("<" * (@mem.ptr - to))
    end
    @mem.ptr = to
  end

  def code(code_text)
    @source << code_text
  end
end
