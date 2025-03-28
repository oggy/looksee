module Looksee
  module PrettyPrintHack
    def pretty_print(pp)
      # In the default IRB inspect mode (pp), IRB assumes that an inspect string
      # that doesn't look like a bunch of known patterns is a code blob, and
      # formats accordingly. That messes up our color escapes.
      if Object.const_defined?(:IRB) && IRB.const_defined?(:ColorPrinter) && pp.is_a?(IRB::ColorPrinter)
        PP.instance_method(:text).bind(pp).call(inspect)
      else
        pp.text(inspect)
      end
    end
  end
end
