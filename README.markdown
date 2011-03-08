# Looksee

Shows you the method lookup path of objects in ways not possible in
plain ruby.

## How

Install me:

    gem install looksee

Pop this in your `.irbrc`:

    require 'looksee'

Now each object has a method `ls`, which shows you all its methods.

    irb(main):001:0> [].ls
    => Array
      &            concat      frozen?      push          taguri
      *            count       hash         rassoc        taguri=
      +            cycle       include?     reject        take
      -            delete      index        reject!       take_while
      <<           delete_at   indexes      replace       to_a
      <=>          delete_if   indices      reverse       to_ary
      ==           drop        insert       reverse!      to_s
      []           drop_while  inspect      reverse_each  to_yaml
      []=          each        join         rindex        transpose
      assoc        each_index  last         select        uniq
      at           empty?      length       shift         uniq!
      choice       eql?        map          shuffle       unshift
      clear        fetch       map!         shuffle!      values_at
      collect      fill        nitems       size          yaml_initialize
      collect!     find_index  pack         slice         zip
      combination  first       permutation  slice!        |
      compact      flatten     pop          sort
      compact!     flatten!    product      sort!
    Enumerable
      all?        each_slice       first     min        reverse_each
      any?        each_with_index  grep      min_by     select
      collect     entries          group_by  minmax     sort
      count       enum_cons        include?  minmax_by  sort_by
      cycle       enum_slice       inject    none?      take
      detect      enum_with_index  map       one?       take_while
      drop        find             max       partition  to_a
      drop_while  find_all         max_by    reduce     zip
      each_cons   find_index       member?   reject
    Object
      taguri  taguri=  to_yaml  to_yaml_properties  to_yaml_style
    Kernel
      ==        hash                        object_id
      ===       id                          private_methods
      =~        inspect                     protected_methods
      __id__    instance_eval               public_methods
      __send__  instance_exec               respond_to?
      class     instance_of?                send
      clone     instance_variable_defined?  singleton_methods
      display   instance_variable_get       taint
      dup       instance_variable_set       tainted?
      enum_for  instance_variables          tap
      eql?      is_a?                       to_a
      equal?    kind_of?                    to_enum
      extend    method                      to_s
      freeze    methods                     type
      frozen?   nil?                        untaint

It'll also color the methods according to whether they're public,
protected, private, undefined (using Module#undef_method), or
overridden. So pretty! By default:

    public:     white
    public:     green
    protected:  yellow
    private:    red
    undefined:  blue
    overridden: black

By default, it shows public and protected methods. Add private ones
like so:

    [].ls :private

Or if you don't want protected:

    [].ls :noprotected

There are variations too. And you can configure things. And you can
use it as a library without polluting the built-in classes. See:

    $ ri Looksee

Or do this in IRB for a quick reference:

    Looksee.help

Enjoy!

## Support

Looksee works with MRI/REE, JRuby, and Rubinius.

## Contributing

 * [Bug reports](https://github.com/oggy/looksee/issues)
 * [Source](https://github.com/oggy/looksee)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
