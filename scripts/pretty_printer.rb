class PrettyPrinter
  INDENT_STEP = 2
  class << self
    def pretty_print(source)
      indent = 0

      source.chars.each do |ch|
        case ch
        when '['
          print("\n#{ " " * indent }[\n")
          indent += INDENT_STEP
          print(" " * indent)
        when ']'
          indent -= INDENT_STEP
          print("\n#{ " " * indent }]\n#{ " " * indent }")
        else
          print(ch)
        end
      end
    end
  end
end
