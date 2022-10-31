require 'spec_helper'

describe Looksee::Inspector do
  include TemporaryClasses
  use_test_adapter

  describe "#inspect" do
    before do
      Looksee.stub(:default_lookup_path_options).and_return({})
      Looksee.stub(:styles).and_return(Hash.new{'%s'})

      @object = Object.new
      temporary_module :M
      temporary_class(:C) { include M }
      Looksee.adapter.ancestors[@object] = [C, M]
    end

    describe "output width" do
      before do
        add_methods C, public: ['aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj']
        add_methods M, public: ['aaa', 'bbb', 'ccc', 'ddd', 'eee', 'fff', 'ggg', 'hhh']
        @lookup_path = Looksee::LookupPath.new(@object)
      end

      it "should columnize output to the given width, if any" do
        inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public], :width => 20)
        inspector.inspect.should == <<-EOS.demargin.chomp
          |M
          |  aaa  ccc  eee  ggg
          |  bbb  ddd  fff  hhh
          |C
          |  aa  cc  ee  gg  ii
          |  bb  dd  ff  hh  jj
        EOS
      end

      it "should columnize output to the current terminal width, if detectable" do
        original_columns = ENV['COLUMNS']
        ENV['COLUMNS'] = '20'
        begin
          inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public])
          inspector.inspect.should == <<-EOS.demargin.chomp
            |M
            |  aaa  ccc  eee  ggg
            |  bbb  ddd  fff  hhh
            |C
            |  aa  cc  ee  gg  ii
            |  bb  dd  ff  hh  jj
          EOS
        ensure
          ENV['COLUMNS'] = original_columns
        end
      end

      it "should columnize output to the configured default otherwise" do
        Looksee.stub(:default_width).and_return(20)
        inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public])
        inspector.inspect.should == <<-EOS.demargin.chomp
          |M
          |  aaa  ccc  eee  ggg
          |  bbb  ddd  fff  hhh
          |C
          |  aa  cc  ee  gg  ii
          |  bb  dd  ff  hh  jj
        EOS
      end
    end

    it "should not show any blank lines if a module has no methods" do
      add_methods M, public: [:pub1, :pub2]
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |  pub1  pub2
        |C
      EOS
    end

    it "should show singleton classes as class names in brackets" do
      Looksee.adapter.ancestors[C] = [C.singleton_class]
      add_methods C.singleton_class, public: [:pub1, :pub2]
      lookup_path = Looksee::LookupPath.new(C)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[C]
        |  pub1  pub2
      EOS
    end

    it "should handle singleton classes of singleton classes correctly" do
      Looksee.adapter.ancestors[C.singleton_class] = [C.singleton_class.singleton_class]
      add_methods C.singleton_class.singleton_class, public: [:pub1, :pub2]
      lookup_path = Looksee::LookupPath.new(C.singleton_class)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[[C]]
        |  pub1  pub2
      EOS
    end

    it "should only show methods of the selected visibilities" do
      temporary_class :E
      add_methods(E, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      Looksee.adapter.ancestors[@object] = [E]
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:protected])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |E
        |  pro
      EOS
    end

    it "should show overridden methods if selected" do
      add_methods(C, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      add_methods(M, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |  pub
        |C
        |  pub
      EOS
    end

    it "should not show overridden methods if not selected" do
      add_methods(C, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      add_methods(M, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :nooverridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |C
        |  pub
      EOS
    end

    it "should only show methods that match the given filters, if any are given" do
      add_methods C, public: [:ab, :ax, :ba, :xa]
      add_methods M, public: [:ab, :ax, :ba, :xa]
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :overridden], :filters => [/^a/, 'b'])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |  ab  ax  ba
        |C
        |  ab  ax  ba
      EOS
    end
  end

  describe "#pretty_print" do
    before do
      Looksee.stub(:default_lookup_path_options).and_return({})
      Looksee.stub(:styles).and_return(Hash.new{"\e[1;31m%s\e[0m"})

      @object = Object.new
      temporary_class :C
      Looksee.adapter.ancestors[@object] = [C]

      add_methods C, public: ['aa']
      @lookup_path = Looksee::LookupPath.new(@object)
      @inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public])
    end

    it "should produce the same output as #inspect" do
      pp = PP.new
      @inspector.pretty_print(pp)
      pp.output.should == <<-EOS.demargin.chomp
        |\e[1;31mC\e[0m
        |  \e[1;31maa\e[0m
      EOS
    end

    it "should not get messed up by IRB::ColorPrinter" do
      begin
        require 'irb/color_printer'
        has_irb_color_printer = true
      rescue LoadError
        has_irb_color_printer = false
      end

      if has_irb_color_printer
        pp = IRB::ColorPrinter.new
        @inspector.pretty_print(pp)
        pp.output.should == <<-EOS.demargin.chomp
          |\e[1;31mC\e[0m
          |  \e[1;31maa\e[0m
        EOS
      end
    end
  end

  describe ".styles" do
    before do
      styles = {
        :module     => "`%s'",
        :public     => "{%s}",
        :protected  => "[%s]",
        :private    => "<%s>",
        :undefined  => "~%s~",
        :overridden => "(%s)",
      }
      Looksee.stub(:styles).and_return(styles)
    end

    it "should delimit each word with the configured delimiters" do
      temporary_class :C
      c = C.new
      Looksee.adapter.ancestors[c] = [C]
      add_methods(C, public: [:pub], protected: [:pro], private: [:pri], undefined: [:und])
      lookup_path = Looksee::LookupPath.new(c)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :protected, :private, :undefined, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |\`C\'
        |  <pri>  [pro]  {pub}  ~und~
      EOS
    end
  end
end
