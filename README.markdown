# Looksee [![Build Status](https://travis-ci.org/oggy/looksee.png)](https://travis-ci.org/oggy/looksee) [![Gem Version](https://badge.fury.io/rb/looksee.svg)](http://badge.fury.io/rb/looksee)

A tool for illustrating the ancestry and method lookup path of
objects. Handy for exploring unfamiliar codebases.

## How

Install me:

    gem install looksee

Pop this in your `.irbrc`:

    require 'looksee'

Now each object has a method `look`, which shows you all its methods.

    irb> [].look
    =>
    BasicObject
      !       __send__       instance_exec             singleton_method_undefined
      !=      equal?         method_missing
      ==      initialize     singleton_method_added
      __id__  instance_eval  singleton_method_removed
    Kernel
      !~                       format                      public_method
      <=>                      freeze                      public_methods
      ===                      frozen?                     public_send
      Array                    gem                         putc
      Complex                  gem_original_require        puts
      Float                    gets                        raise
      Hash                     global_variables            rand
      Integer                  hash                        readline
      Pathname                 initialize_clone            readlines
      Rational                 initialize_copy             remove_instance_variable
      String                   initialize_dup              require
      __callee__               inspect                     require_relative
      __dir__                  instance_of?                respond_to?
      __method__               instance_variable_defined?  respond_to_missing?
      `                        instance_variable_get       select
      abort                    instance_variable_set       send
      at_exit                  instance_variables          set_trace_func
      autoload                 is_a?                       singleton_class
      autoload?                iterator?                   singleton_method
      binding                  itself                      singleton_methods
      block_given?             kind_of?                    sleep
      caller                   lambda                      spawn
      caller_locations         load                        sprintf
      catch                    local_variables             srand
      class                    loop                        syscall
      clone                    method                      system
      define_singleton_method  methods                     tap
      display                  nil?                        test
      dup                      object_id                   then
      enum_for                 open                        throw
      eql?                     p                           to_enum
      eval                     pp                          to_s
      exec                     pretty_inspect              trace_var
      exit                     print                       trap
      exit!                    printf                      untrace_var
      extend                   private_methods             warn
      fail                     proc                        yield_self
      fork                     protected_methods
    Looksee::ObjectMixin
      look
    PP::ObjectMixin
      pretty_print        pretty_print_inspect
      pretty_print_cycle  pretty_print_instance_variables
    Object
      DelegateClass
    Enumerable
      all?            drop              find_all    max        reject        tally
      any?            drop_while        find_index  max_by     reverse_each  to_a
      chain           each_cons         first       member?    select        to_h
      chunk           each_entry        flat_map    min        slice_after   to_set
      chunk_while     each_slice        grep        min_by     slice_before  uniq
      collect         each_with_index   grep_v      minmax     slice_when    zip
      collect_concat  each_with_object  group_by    minmax_by  sort
      compact         entries           include?    none?      sort_by
      count           filter            inject      one?       sum
      cycle           filter_map        lazy        partition  take
      detect          find              map         reduce     take_while
    Array
      &              count        include?         pretty_print          size
      *              cycle        index            pretty_print_cycle    slice
      +              deconstruct  initialize       product               slice!
      -              delete       initialize_copy  push                  sort
      <<             delete_at    insert           rassoc                sort!
      <=>            delete_if    inspect          reject                sort_by!
      ==             difference   intersect?       reject!               sum
      []             dig          intersection     repeated_combination  take
      []=            drop         join             repeated_permutation  take_while
      all?           drop_while   keep_if          replace               to_a
      any?           each         last             reverse               to_ary
      append         each_index   length           reverse!              to_h
      assoc          empty?       map              reverse_each          to_s
      at             eql?         map!             rindex                transpose
      bsearch        fetch        max              rotate                union
      bsearch_index  fill         min              rotate!               uniq
      clear          filter       minmax           sample                uniq!
      collect        filter!      none?            select                unshift
      collect!       find_index   one?             select!               values_at
      combination    first        pack             shelljoin             zip
      compact        flatten      permutation      shift                 |
      compact!       flatten!     pop              shuffle
      concat         hash         prepend          shuffle!

Methods are colored according to whether they're public, protected,
private, undefined (using Module#undef_method), or overridden.

(Undefined methods are not shown on MRI 2.3 due to interpreter limitations.)

You can hide, say, private methods like this:

    irb> [].look :noprivate

Or filter the list by Regexp:

    irb> [].look /^to_/
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

## Proxy objects

Objects that delegate everything via `method_missing` to some other object can
be tricky, because they will delegate `look` itself. To view such objects, you
can always do:

    Looksee[object]

This will also work for `BasicObject` instances that don't have an `look`
method.  `Object#look` is simply a wrapper around `Looksee.[]`.

## To the source!

If you want to know more about any of those methods, Looksee can
take you straight to the source in your editor:

    [].look.edit :to_set

By default, this uses `vi`; customize it like this:

    # %f = file, %l = line number
    Looksee.editor = "mate -l%l %f"

## `look` in your way?

If you have a library that for some reason can't handle an `look` method
existing on `Object`, you may rename it like this:

    Looksee.rename :_look

## Quick Reference

We've got one:

    Looksee.help

Enjoy!

## Troubleshooting

### ANSI Escapes

If your pager is not configured, you may see ugly output like this:

    ESC[1;37mArrayESC[0m
    ESC[1;32m&ESC[0m ESC[1;32mcompact!ESC[0m ESC[1;32minclude?ESC[0m
    ESC[1;32mrassocESC[0m ESC[1;32mto_aESC[0m

The most common pager is `less`, which you can configure by setting an
environment variable like this in your shell configuration (usually
`~/.bashrc`):

    export LESS=-R

## Contributing

 * [Bug reports](https://github.com/oggy/looksee/issues)
 * [Source](https://github.com/oggy/looksee)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
