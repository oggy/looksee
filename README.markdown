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
      !   __send__    instance_eval   singleton_method_added    
      !=  equal?      instance_exec   singleton_method_removed  
      ==  initialize  method_missing  singleton_method_undefined
    Kernel
      !~                       freeze                      puts                    
      <=>                      frozen?                     raise                   
      ===                      gem                         rand                    
      =~                       gem_original_require        readline                
      Array                    gets                        readlines               
      Complex                  global_variables            remove_instance_variable
      Float                    hash                        require                 
      Integer                  initialize_clone            require_relative        
      Rational                 initialize_copy             respond_to?             
      String                   initialize_dup              respond_to_missing?     
      URI                      inspect                     select                  
      __callee__               instance_of?                send                    
      __id__                   instance_variable_defined?  set_trace_func          
      __method__               instance_variable_get       singleton_class         
      `                        instance_variable_set       singleton_methods       
      abort                    instance_variables          sleep                   
      at_exit                  is_a?                       spawn                   
      autoload                 iterator?                   sprintf                 
      autoload?                kind_of?                    srand                   
      binding                  lambda                      syscall                 
      block_given?             load                        system                  
      caller                   local_variables             taint                   
      catch                    loop                        tainted?                
      class                    method                      tap                     
      clone                    methods                     test                    
      define_singleton_method  nil?                        throw                   
      display                  object_id                   to_enum                 
      dup                      open                        to_s                    
      enum_for                 p                           trace_var               
      eql?                     print                       trap                    
      eval                     printf                      trust                   
      exec                     private_methods             untaint                 
      exit                     proc                        untrace_var             
      exit!                    protected_methods           untrust                 
      extend                   public_method               untrusted?              
      fail                     public_methods              warn                    
      fork                     public_send                 y                       
      format                   putc                      
    Looksee::ObjectMixin
      edit  ls
    Object
      default_src_encoding  oauth            taguri   to_yaml_properties
      in?                   patch            taguri=  to_yaml_style     
      irb_binding           singleton_class  timeout
      load_if_available     syck_to_yaml     to_yaml
    Enumerable
      all?            drop_while        first     min           select      
      any?            each_cons         flat_map  min_by        slice_before
      by              each_entry        grep      minmax        sort        
      chunk           each_slice        group_by  minmax_by     sort_by     
      collect         each_with_index   include?  none?         take        
      collect_concat  each_with_object  inject    one?          take_while  
      count           entries           map       partition     to_a        
      cycle           find              max       reduce        to_set      
      detect          find_all          max_by    reject        zip         
      drop            find_index        member?   reverse_each
    Array
      &            drop_while       map!                  size           
      *            each             pack                  slice          
      +            each_index       permutation           slice!         
      -            empty?           pop                   sort           
      <<           eql?             product               sort!          
      <=>          fetch            push                  sort_by!       
      ==           fill             rassoc                taguri         
      []           find_index       reject                taguri=        
      []=          first            reject!               take           
      assoc        flatten          repeated_combination  take_while     
      at           flatten!         repeated_permutation  to_a           
      clear        frozen?          replace               to_ary         
      collect      hash             reverse               to_s           
      collect!     include?         reverse!              to_yaml        
      combination  index            reverse_each          transpose      
      compact      initialize       rindex                uniq           
      compact!     initialize_copy  rotate                uniq!          
      concat       insert           rotate!               unshift        
      count        inspect          sample                values_at      
      cycle        join             select                yaml_initialize
      delete       keep_if          select!               zip            
      delete_at    last             shift                 |              
      delete_if    length           shuffle             
      drop         map              shuffle!             

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

    > [].edit('to_set')

By default, this uses `vi`; customize it like this:

    # %f = file, %l = line number
    Looksee.editor = "mate -l%l %f"

See more in the quick reference:

    irb> Looksee.help

Enjoy!

## Support

Looksee works with:

 *  MRI/REE (>= 1.8.6)
 * JRuby (>= 1.5.6)
 * Rubinius (>= 1.2.1)

## Contributing

 * [Bug reports](https://github.com/oggy/looksee/issues)
 * [Source](https://github.com/oggy/looksee)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
