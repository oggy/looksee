require 'spec_helper'

describe Looksee::Inspector do
  include TemporaryClasses

  def stub_methods(mod, public, protected, private, undefined)
    Looksee.stubs(:internal_public_instance_methods   ).with(mod).returns(public)
    Looksee.stubs(:internal_protected_instance_methods).with(mod).returns(protected)
    Looksee.stubs(:internal_private_instance_methods  ).with(mod).returns(private)
    Looksee.stubs(:internal_undefined_instance_methods).with(mod).returns(undefined)
  end

  describe "#inspect" do
    before do
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee.stubs(:styles).returns(Hash.new{'%s'})

      @object = Object.new
      temporary_module :M
      temporary_class(:C) { include M }
      Looksee.stubs(:lookup_modules).with(@object).returns([C, M])
    end

    describe "output width" do
      before do
        stub_methods(C, ['aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj'], [], [], [])
        stub_methods(M, ['aaa', 'bbb', 'ccc', 'ddd', 'eee', 'fff', 'ggg', 'hhh'], [], [], [])
        @lookup_path = Looksee::LookupPath.new(@object)
      end

      it "should columnize output to the given width, if any" do
        inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public], :width => 20)
        inspector.inspect.should == <<-EOS.demargin.chomp
          |C
          |  aa  cc  ee  gg  ii
          |  bb  dd  ff  hh  jj
          |M
          |  aaa  ccc  eee  ggg
          |  bbb  ddd  fff  hhh
        EOS
      end

      it "should columnize output to the current terminal width, if detectable" do
        original_columns = ENV['COLUMNS']
        ENV['COLUMNS'] = '20'
        begin
          inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public])
          inspector.inspect.should == <<-EOS.demargin.chomp
            |C
            |  aa  cc  ee  gg  ii
            |  bb  dd  ff  hh  jj
            |M
            |  aaa  ccc  eee  ggg
            |  bbb  ddd  fff  hhh
          EOS
        ensure
          ENV['COLUMNS'] = original_columns
        end
      end

      it "should columnize output to the configured default otherwise" do
        Looksee.stubs(:default_width).returns(20)
        inspector = Looksee::Inspector.new(@lookup_path, :visibilities => [:public])
        inspector.inspect.should == <<-EOS.demargin.chomp
          |C
          |  aa  cc  ee  gg  ii
          |  bb  dd  ff  hh  jj
          |M
          |  aaa  ccc  eee  ggg
          |  bbb  ddd  fff  hhh
        EOS
      end
    end

    it "should not show any blank lines if a module has no methods" do
      stub_methods(C, [], [], [], [])
      stub_methods(M, ['public1', 'public2'], [], [], [])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |C
        |M
        |  public1  public2
      EOS
    end

    it "should show singleton classes as class names in brackets" do
      Looksee.stubs(:lookup_modules).with(C).returns([C.singleton_class])
      stub_methods(C.singleton_class, ['public1', 'public2'], [], [], [])
      lookup_path = Looksee::LookupPath.new(C)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[C]
        |  public1  public2
      EOS
    end

    it "should handle singleton classes of singleton classes correctly" do
      Looksee.stubs(:lookup_modules).with(C.singleton_class).returns([C.singleton_class.singleton_class])
      stub_methods(C.singleton_class.singleton_class, ['public1', 'public2'], [], [], [])
      lookup_path = Looksee::LookupPath.new(C.singleton_class)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |[[C]]
        |  public1  public2
      EOS
    end

    it "should only show methods of the selected visibilities" do
      temporary_class :E
      stub_methods(E, ['public'], ['protected'], ['private'], ['undefined'])
      Looksee.stubs(:lookup_modules).with(@object).returns([E])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:protected])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |E
        |  protected
      EOS
    end

    it "should show overridden methods if selected" do
      stub_methods(C, ['public'], ['protected'], ['private'], ['undefined'])
      stub_methods(M, ['public'], ['protected'], ['private'], ['undefined'])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |C
        |  public
        |M
        |  public
      EOS
    end

    it "should not show overridden methods if not selected" do
      stub_methods(C, ['public'], ['protected'], ['private'], ['undefined'])
      stub_methods(M, ['public'], ['protected'], ['private'], ['undefined'])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :nooverridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |C
        |  public
        |M
      EOS
    end

    it "should only show methods that match the given filters, if any are given" do
      stub_methods(C, %w'ab ax ba xa', [], [], [])
      stub_methods(M, %w'ab ax ba xa', [], [], [])
      lookup_path = Looksee::LookupPath.new(@object)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :overridden], :filters => [/^a/, 'b'])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |C
        |  ab  ax  ba
        |M
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
      Looksee.stubs(:lookup_modules).returns([C])
      stub_methods(C, ['public'], ['protected'], ['private'], ['undefined'])
      lookup_path = Looksee::LookupPath.new(Object.new)
      inspector = Looksee::Inspector.new(lookup_path, :visibilities => [:public, :protected, :private, :undefined, :overridden])
      inspector.inspect.should == <<-EOS.demargin.chomp
        |\`C\'
        |  <private>  [protected]  {public}  ~undefined~
      EOS
    end
  end
end
