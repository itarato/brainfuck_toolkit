class Interpreter
  MEM_SIZE = 256

  def self.execute(source = "")
    new(source).execute
  end

  def initialize(source = "")
    @source = source
    @mem = [0] * MEM_SIZE
    @mem_p = 0
    @pc = 0

    @bracket_goto_map = setup_bracket_goto_map
  end

  def execute
    while !complete?
      case (instruction = read_instruction)
      when '>' then mem_p_inc
      when '<' then mem_p_dec
      when '+' then mem_inc
      when '-' then mem_dec
      when '.' then mem_print
      when ',' then mem_read_char
      when '[' then loop_cond_fwd_jump
      when ']' then loop_cond_bwd_jump
      end

      pc_inc
    end
  end

  private

  def setup_bracket_goto_map
    map = {}
    bracket_mem = []

    @source.chars.each_with_index do |ch, i|
      if ch == '['
        map[i] = nil
        bracket_mem.push(i)
      elsif ch == ']'
        raise("Incorrect brackets") unless bracket_mem.size > 0
        last_bracket_idx = bracket_mem.pop
        map[i] = last_bracket_idx
        map[last_bracket_idx] = i
      end
    end

    map
  end

  def complete?
    @pc >= @source.size
  end

  def read_instruction
    @source[@pc]
  end

  def mem_p_inc
    @mem_p += 1
  end

  def mem_p_dec
    @mem_p -= 1
  end

  def mem_inc
    @mem[@mem_p] += 1
  end

  def mem_dec
    @mem[@mem_p] -= 1
  end

  def mem_print
    print(@mem[@mem_p].chr)
    STDOUT.flush
  end

  def mem_read_char
    puts "?>"
    system('stty raw -echo')
    @mem[@mem_p] = STDIN.getc.ord
    system('stty -raw echo')
  end

  def loop_cond_fwd_jump
    return if @mem[@mem_p] != 0
    @pc = @bracket_goto_map[@pc]
  end

  def loop_cond_bwd_jump
    return if @mem[@mem_p] == 0
    @pc = @bracket_goto_map[@pc]
  end

  def pc_inc
    @pc += 1
  end
end
