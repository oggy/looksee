require 'shellwords'

module Looksee
  class Editor
    def initialize(command)
      @command = command.dup
      infer_arguments
    end

    attr_reader :command

    #
    # Run the editor command for the +method_name+ of +object+.
    #
    def edit(object, method_name)
      method = LookupPath.new(object).find(method_name.to_s) or
        return
      file, line = Looksee.adapter.source_location(method)
      run(file, line) unless line.nil?
    end

    #
    # Run the editor command for the given file and line.
    #
    def run(file, line)
      system *command_for(file, line)
    end

    #
    # Return the editor command for the given file and line.
    #
    # This is an array of the command with its arguments.
    #
    def command_for(file, line)
      line = line.to_s
      words = Shellwords.shellwords(command)
      words.map! do |word|
        word.gsub!(/%f/, file)
        word.gsub!(/%l/, line)
        word.gsub!(/%%/, '%')
        word
      end
    end

    private

    def infer_arguments
      return if command =~ /%[fl]/

      case command[/\S+/]
      when /\A(?:g?vim?|.*macs|pico|nano)\z/
        command << " +%l %f"
      when 'mate'
        command << " -l%l %f"
      end
    end
  end
end
