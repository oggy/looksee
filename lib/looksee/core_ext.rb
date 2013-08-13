module Looksee
  module ObjectMixin
    #
    # Return a Looksee::Inspector for this object.
    #
    # +args+ is an optional list of specifiers.
    #
    #   * +:public+ - include public methods
    #   * +:protected+ - include public methods
    #   * +:private+ - include public methods
    #   * +:undefined+ - include public methods (see Module#undef_method)
    #   * +:overridden+ - include public methods
    #   * +:nopublic+ - include public methods
    #   * +:noprotected+ - include public methods
    #   * +:noprivate+ - include public methods
    #   * +:noundefined+ - include public methods (see Module#undef_method)
    #   * +:nooverridden+ - include public methods
    #   * a string - only include methods containing this string (may
    #     be used multiple times)
    #   * a regexp - only include methods matching this regexp (may
    #     be used multiple times)
    #
    # The default (if options is nil or omitted) is given by
    # #default_lookup_path_options.
    #
    def ls(*args)
      options = {:visibilities => Set[], :filters => Set[]}
      (Looksee.default_specifiers + args).each do |arg|
        case arg
        when String, Regexp
          options[:filters] << arg
        when :public, :protected, :private, :undefined, :overridden
          options[:visibilities].add(arg)
        when :nopublic, :noprotected, :noprivate, :noundefined, :nooverridden
          visibility = arg.to_s.sub(/\Ano/, '').to_sym
          options[:visibilities].delete(visibility)
        else
          raise ArgumentError, "invalid specifier: #{arg.inspect}"
        end
      end
      lookup_path = LookupPath.new(self)
      Inspector.new(lookup_path, options)
    end

    def self.rename(renamings)  # :nodoc:
      renamings.each do |old_name, new_name|
        alias_method new_name, old_name
        remove_method old_name
      end
    end
  end

  #
  # Rename the #ls method, added to every object. Example:
  #
  #     rename :_ls
  #
  # This renames Looksee's #ls method to #_ls.
  #
  # For backward compatibility, the old-style invocation is also
  # supported. Please note this is deprecated.
  #
  #     rename :ls => :_ls
  #
  def self.rename(renamings)
    renamings = {:ls => renamings} if !renamings.is_a?(Hash)
    ObjectMixin.rename(renamings)
  end

  (ENV['LOOKSEE_METHODS'] || '').scan(/([\w_]+)=([\w_]+)/) do
    rename $1.to_sym => $2.to_sym
  end

  Object.send :include, ObjectMixin
end
