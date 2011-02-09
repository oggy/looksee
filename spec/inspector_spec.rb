require 'spec_helper'

describe Looksee::Inspector do
  include TemporaryClasses

  describe "#inspect" do
    before do
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee.stubs(:styles).returns(Hash.new{'%s'})

      @object = Object.new
      temporary_module :M
      temporary_class(:C) { include M }
      Looksee.adapter.ancestors[@object] = [C, M]
    end

    describe "output width" do
      before do
        Looksee.adapter.public_methods[C] = ['aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj']
        Looksee.adapter.public_methods[M] = ['aaa', 'bbb', 'ccc', 'ddd', 'eee', 'fff', 'ggg', 'hhh']
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
        Looksee.stubs(:default_width).returns(20)
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
      Looksee.adapter.public_methods[M] = [:public1, :public2]
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |  public1  public2
        |C
      EOS
    end

    it "should show singleton classes as class names in brackets" do
      Looksee.adapter.ancestors[C] = [C.singleton_class]
      Looksee.adapter.public_methods[C.singleton_class] = [:public1, :public2]
      lookup_path = Looksee::LookupPath.new(C)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[C]
        |  public1  public2
      EOS
    end

    it "should handle singleton classes of singleton classes correctly" do
      Looksee.adapter.ancestors[C.singleton_class] = [C.singleton_class.singleton_class]
      Looksee.adapter.public_methods[C.singleton_class.singleton_class] = [:public1, :public2]
      lookup_path = Looksee::LookupPath.new(C.singleton_class)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[[C]]
        |  public1  public2
      EOS
    end

    it "should only show methods of the selected visibilities" do
      temporary_class :E
      Looksee.adapter.set_methods(E, [:public], [:protected], [:private], [:undefined])
      Looksee.adapter.ancestors[@object] = [E]
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:protected])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |E
        |  protected
      EOS
    end

    it "should show overridden methods if selected" do
      Looksee.adapter.set_methods(C, [:public], [:protected], [:private], [:undefined])
      Looksee.adapter.set_methods(M, [:public], [:protected], [:private], [:undefined])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |  public
        |C
        |  public
      EOS
    end

    it "should not show overridden methods if not selected" do
      Looksee.adapter.set_methods(C, [:public], [:protected], [:private], [:undefined])
      Looksee.adapter.set_methods(M, [:public], [:protected], [:private], [:undefined])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :nooverridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |M
        |C
        |  public
      EOS
    end

    it "should only show methods that match the given filters, if any are given" do
      Looksee.adapter.public_methods[C] = [:ab, :ax, :ba, :xa]
      Looksee.adapter.public_methods[M] = [:ab, :ax, :ba, :xa]
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
      Looksee.stubs(:styles).returns(styles)
    end

    it "should delimit each word with the configured delimiters" do
      temporary_class :C
      c = C.new
      Looksee.adapter.ancestors[c] = [C]
      Looksee.adapter.set_methods(C, [:public], [:protected], [:private], [:undefined])
      lookup_path = Looksee::LookupPath.new(c)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :protected, :private, :undefined, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |\`C\'
        |  <private>  [protected]  {public}  ~undefined~
      EOS
    end
  end
end
