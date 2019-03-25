# Looksee [![Build Status](https://travis-ci.org/oggy/looksee.png)](https://travis-ci.org/oggy/looksee) [![Gem Version](https://badge.fury.io/rb/looksee.svg)](http://badge.fury.io/rb/looksee)

A tool for illustrating the ancestry and method lookup path of
objects. Handy for exploring unfamiliar codebases.

## How

Install me:

    gem install looksee

Pop this in your `.irbrc`:

    require 'looksee'

Now each object has a method `ls`, which shows you all its methods.

    irb> [].ls
    => BasicObject
      !   __id__    initialize     method_missing            singleton_method_undefined
      !=  __send__  instance_eval  singleton_method_added
      ==  equal?    instance_exec  singleton_method_removed
    Kernel
      !~                       enum_for                    kind_of?                  respond_to_missing?
      <=>                      eql?                        lambda                    select
      ===                      eval                        load                      send
      =~                       exec                        local_variables           set_trace_func
      Array                    exit                        loop                      singleton_class
      Complex                  exit!                       method                    singleton_method
      Float                    extend                      methods                   singleton_methods
      Hash                     fail                        nil?                      sleep
      Integer                  fork                        object_id                 spawn
      Rational                 format                      open                      sprintf
      String                   freeze                      p                         srand
      __callee__               frozen?                     print                     syscall
      __dir__                  gem                         printf                    system
      __method__               gem_original_require        private_methods           taint
      `                        gets                        proc                      tainted?
      abort                    global_variables            protected_methods         tap
      at_exit                  hash                        public_method             test
      autoload                 initialize_clone            public_methods            throw
      autoload?                initialize_copy             public_send               to_enum
      binding                  initialize_dup              putc                      to_s
      block_given?             inspect                     puts                      trace_var
      caller                   instance_of?                raise                     trap
      caller_locations         instance_variable_defined?  rand                      trust
      catch                    instance_variable_get       readline                  untaint
      class                    instance_variable_set       readlines                 untrace_var
      clone                    instance_variables          remove_instance_variable  untrust
      define_singleton_method  is_a?                       require                   untrusted?
      display                  iterator?                   require_relative          warn
      dup                      itself                      respond_to?
    Looksee::ObjectMixin
      ls
    Object
      DelegateClass  default_src_encoding  irb_binding
    Enumerable
      all?            detect            entries     group_by  min        reject        take
      any?            drop              find        include?  min_by     reverse_each  take_while
      chunk           drop_while        find_all    inject    minmax     select        to_a
      chunk_while     each_cons         find_index  lazy      minmax_by  slice_after   to_h
      collect         each_entry        first       map       none?      slice_before  to_set
      collect_concat  each_slice        flat_map    max       one?       slice_when    zip
      count           each_with_index   grep        max_by    partition  sort
      cycle           each_with_object  grep_v      member?   reduce     sort_by
    Array
      &              collect!     eql?             keep_if               reverse       sort!
      *              combination  fetch            last                  reverse!      sort_by!
      +              compact      fill             length                reverse_each  take
      -              compact!     find_index       map                   rindex        take_while
      <<             concat       first            map!                  rotate        to_a
      <=>            count        flatten          pack                  rotate!       to_ary
      ==             cycle        flatten!         permutation           sample        to_h
      []             delete       frozen?          pop                   select        to_s
      []=            delete_at    hash             product               select!       transpose
      any?           delete_if    include?         push                  shift         uniq
      assoc          dig          index            rassoc                shuffle       uniq!
      at             drop         initialize       reject                shuffle!      unshift
      bsearch        drop_while   initialize_copy  reject!               size          values_at
      bsearch_index  each         insert           repeated_combination  slice         zip
      clear          each_index   inspect          repeated_permutation  slice!        |
      collect        empty?       join             replace               sort

Methods are colored according to whether they're public, protected,
private, undefined (using Module#undef_method), or overridden.

(Undefined methods are not shown on MRI 2.3 due to interpreter limitations.)

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

## Proxy objects

Objects that delegate everything via `method_missing` to some other object can
be tricky, because they will delegate `ls` itself. To view such objects, you can
always do:

    Looksee[object]

This will also work for `BasicObject` instances that don't have an `ls` method.
`Object#ls` is simply a wrapper around `Looksee.[]`.

## To the source!

If you want to know more about any of those methods, Looksee can
take you straight to the source in your editor:

    [].ls.edit :to_set

By default, this uses `vi`; customize it like this:

    # %f = file, %l = line number
    Looksee.editor = "mate -l%l %f"

## `ls` in your way?

If you have a library that for some reason can't handle an `ls` method existing
on `Object`, you may rename it like this:

    Looksee.rename :_ls

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
