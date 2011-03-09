module Looksee
  class Help
    def inspect
      <<-EOS.gsub(/^ *\|/, '')
        |== Looksee Quick Reference
        |
        |  object.ls(*specifiers)
        |    Print the methods of \`object\'.
        |
        |    Available specifiers:
        |
        |      :public     :private    :overridden
        |      :protected  :undefined
        |        Print methods with these visibilities.
        |
        |      :nopublic     :noprivate    :nooverridden
        |      :noprotected  :noundefined
        |        Do not print methods with these visibilities.
        |
        |      "string"
        |        Print methods containing this string.
        |
        |      /regexp/
        |        Print methods matching this regexp.
        |
        |    Styles:
        |
        |      #{Looksee.styles[:module] % 'Module'}
        |      #{Looksee.styles[:public] % 'public'}     }
        |      #{Looksee.styles[:protected] % 'protected'}  } like a traffic light!
        |      #{Looksee.styles[:private] % 'private'}    }
        |      #{Looksee.styles[:undefined] % 'undefined'}  ] like a ghost!
        |      #{Looksee.styles[:overridden] % 'overridden'} ] like a shadow!
        |
        |      Customize with Looksee.styles:
        |
        |        Looksee.styles = {
        |          :module => '**%s**',
        |          :private => '(%s)',
        |          ...
        |        }
        |
        |  object.edit(method)
        |
        |    Jump to the source of the given method. Set your editor
        |    with Looksee.editor or the LOOKSEE_EDITOR environment
        |    variable. "%f" expands to the file name, "%l" to the line
        |    number. Example:
        |
        |    Looksee.editor = "emacs -nw +%f %l"
      EOS
    end
  end
end
