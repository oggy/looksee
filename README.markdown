# Looksee

A tool for illustrating the ancestry and method lookup path of
objects. Great for exploring unfamiliar codebases!

## How

Install me:

    gem install looksee

Pop this in your `.irbrc`:

    require 'looksee'

Now each object has a method `ls`, which shows you all its methods.

    irb> [].ls
    => BasicObject
      !       __send__       instance_exec             singleton_method_undefined
      !=      equal?         method_missing
      ==      initialize     singleton_method_added
      __id__  instance_eval  singleton_method_removed
    Kernel
      !~                       frozen?                     puts
      <=>                      gem                         raise
      ===                      gem_original_require        rand
      =~                       gets                        readline
      Array                    global_variables            readlines
      Complex                  hash                        remove_instance_variable
      Float                    initialize_clone            require
      Integer                  initialize_copy             require_relative
      Rational                 initialize_dup              respond_to?
      String                   inspect                     respond_to_missing?
      __callee__               instance_of?                select
      __method__               instance_variable_defined?  send
      `                        instance_variable_get       set_trace_func
      abort                    instance_variable_set       singleton_class
      at_exit                  instance_variables          singleton_methods
      autoload                 is_a?                       sleep
      autoload?                iterator?                   spawn
      binding                  kind_of?                    sprintf
      block_given?             lambda                      srand
      caller                   load                        syscall
      catch                    local_variables             system
      class                    loop                        taint
      clone                    method                      tainted?
      define_singleton_method  methods                     tap
      display                  nil?                        test
      dup                      object_id                   throw
      enum_for                 open                        to_enum
      eql?                     p                           to_s
      eval                     print                       trace_var
      exec                     printf                      trap
      exit                     private_methods             trust
      exit!                    proc                        untaint
      extend                   protected_methods           untrace_var
      fail                     public_method               untrust
      fork                     public_methods              untrusted?
      format                   public_send                 warn
      freeze                   putc
    Looksee::ObjectMixin
      ls
    Object
      default_src_encoding  irb_binding
    Enumerable
      all?            each_cons         flat_map  min_by        slice_before
      any?            each_entry        grep      minmax        sort
      chunk           each_slice        group_by  minmax_by     sort_by
      collect         each_with_index   include?  none?         take
      collect_concat  each_with_object  inject    one?          take_while
      count           entries           map       partition     to_a
      cycle           find              max       reduce        to_set
      detect          find_all          max_by    reject        zip
      drop            find_index        member?   reverse_each
      drop_while      first             min       select
    Array
      &            count       hash             rassoc                size
      *            cycle       include?         reject                slice
      +            delete      index            reject!               slice!
      -            delete_at   initialize       repeated_combination  sort
      <<           delete_if   initialize_copy  repeated_permutation  sort!
      <=>          drop        insert           replace               sort_by!
      ==           drop_while  inspect          reverse               take
      []           each        join             reverse!              take_while
      []=          each_index  keep_if          reverse_each          to_a
      assoc        empty?      last             rindex                to_ary
      at           eql?        length           rotate                to_s
      clear        fetch       map              rotate!               transpose
      collect      fill        map!             sample                uniq
      collect!     find_index  pack             select                uniq!
      combination  first       permutation      select!               unshift
      compact      flatten     pop              shift                 values_at
      compact!     flatten!    product          shuffle               zip
      concat       frozen?     push             shuffle!              |

Methods are colored according to whether they're public, protected,
private, undefined (using Module#undef_method), or overridden.

You can hide, say, private methods like this:

    irb> [].ls :noprivate

Or filter the list by Regexp:

    irb> [].ls /^to_/
     => BasicObject
    Kernel
      to_enum  to_s
    Looksee::ObjectMixin
    Object
      to_yaml  to_yaml_properties  to_yaml_style
    Enumerable
      to_a  to_set
    Array
      to_a  to_ary  to_s  to_yaml

And if you want to know more about any of those methods, Looksee can
take you straight to the source in your editor:

    > [].ls.edit('to_set')

By default, this uses `vi`; customize it like this:

    # %f = file, %l = line number
    Looksee.editor = "mate -l%l %f"

See more in the quick reference:

    irb> Looksee.help

Enjoy!

## Support

Looksee supports:

 * MRI 1.8.7, 1.9.2, 1.9.3, 2.0.0
 * REE 1.8.7
 * JRuby 1.6.7
 * Rubinius 1.2.3, 1.2.4

## Contributing

 * [Bug reports](https://github.com/oggy/looksee/issues)
 * [Source](https://github.com/oggy/looksee)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
