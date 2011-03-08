module Looksee
  class Help
    def inspect
      <<-EOS.gsub(/^ *\|/, '')
        |== Looksee Quick Reference
        |
        |  object.edit(method)
        |    Jump to the source of the given method of \`object'. Set
        |    your editor by setting Looksee.editor.
        |
        |  object.ls(specifiers)
        |    Print the method lookup path of \`object\'
        |
        |    Available specifiers:
        |
        |    :public
        |    :protected
        |    :private
        |    :undefined
        |    :overridden
        |      Print methods with this visibility.
        |
        |    :nopublic
        |    :noprotected
        |    :noprivate
        |    :noundefined
        |    :nooverridden
        |      Do not print methods with this visibility.
        |
        |    "string"
        |      Print methods containing this string.
        |
        |    /regexp/
        |      Print methods matching this regexp.
        |
        |  Styles:
        |
        |    #{Looksee.styles[:module] % 'Module'}
        |    #{Looksee.styles[:public] % 'public'}
        |    #{Looksee.styles[:protected] % 'protected'}
        |    #{Looksee.styles[:private] % 'private'}
        |    #{Looksee.styles[:undefined] % 'undefined'}
        |    #{Looksee.styles[:overridden] % 'overridden'}
      EOS
    end
  end
end
