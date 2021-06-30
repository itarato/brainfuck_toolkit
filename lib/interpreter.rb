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

  def execute(screen)
    while !complete?
      case (instruction = read_instruction)
      when '>' then mem_p_inc
      when '<' then mem_p_dec
      when '+' then mem_inc
      when '-' then mem_dec
      when '.' then mem_print(screen)
      when ',' then mem_read_char
      when '[' then loop_cond_fwd_jump
      when ']' then loop_cond_bwd_jump
      when '@' then dump_with_message
      end

      pc_inc
    end
  end

  def dump_with_message
    msg = ""
    pc_inc

    loop do
      pc_inc
      
      break if read_instruction == '}'

      msg << read_instruction
    end

    dump(msg)
  end

  def dump(message = "debug")
    puts "\t<< #{message} >>"

    puts "PC: #{@pc}"
    puts "MP: #{@mem_p}"
    
    puts "Memory:"
    @mem.reverse.drop_while { |v| v == 0 }.reverse.each_with_index { |v, i| puts "  - [#{i}] = #{v}" }
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
    raise("Not enough memory") if @mem_p >= MEM_SIZE - 1
    @mem_p += 1
  end

  def mem_p_dec
    raise("Incorrect mem pointer") if @mem_p <= 0
    @mem_p -= 1
  end

  def mem_inc
    @mem[@mem_p] = (@mem[@mem_p] + 1) & 0xFF
  end

  def mem_dec
    @mem[@mem_p] = (@mem[@mem_p] - 1) & 0xFF
  end

  def mem_print(screen)
    screen << @mem[@mem_p].chr
  end

  def mem_read_char
    print("?>")
    input = STDIN.readline.strip
    @mem[@mem_p] = if input.size > 1 || input =~ /^[0-9]{1,3}$/
      input.to_i
    else
      input[0].ord
    end
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
