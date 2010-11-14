require 'spec_helper'

describe Looksee::LookupPath do
  include TemporaryClasses

  def stub_methods(mod, public, protected, private, undefined)
    Looksee.stubs(:internal_public_instance_methods   ).with(mod).returns(public)
    Looksee.stubs(:internal_protected_instance_methods).with(mod).returns(protected)
    Looksee.stubs(:internal_private_instance_methods  ).with(mod).returns(private)
    Looksee.stubs(:internal_undefined_instance_methods).with(mod).returns(undefined)
  end

  describe "#entries" do
    before do
      temporary_module :M
      temporary_class(:C) { include M }
      stub_methods(C, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
      stub_methods(M, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
      @object = Object.new
      Looksee.stubs(:lookup_modules).with(@object).returns([C, M])
      Looksee::LookupPath.stubs(:default_options).returns({})
    end

    it "should contain an entry for each module in the object's lookup path" do
      Looksee::LookupPath.new(@object).entries.map{|entry| entry.module_name}.should == %w'C M'
    end

    it "should include only non-overridden public methods when public methods are requested" do
      lookup_path = Looksee::LookupPath.new(@object, :public => true)
      lookup_path.entries[0].methods.should == %w'public1 public2'
      lookup_path.entries[1].methods.should == %w'public1 public2'
    end

    it "should include only non-overridden protected methods when protected methods are requested" do
      lookup_path = Looksee::LookupPath.new(@object, :protected => true)
      lookup_path.entries[0].methods.should == %w'protected1 protected2'
      lookup_path.entries[1].methods.should == %w'protected1 protected2'
    end

    it "should include only non-overridden private methods when private methods are requested" do
      lookup_path = Looksee::LookupPath.new(@object, :private => true)
      lookup_path.entries[0].methods.should == %w'private1 private2'
      lookup_path.entries[1].methods.should == %w'private1 private2'
    end

    it "should include only non-overridden undefined methods when undefined methods are requested" do
      lookup_path = Looksee::LookupPath.new(@object, :undefined => true)
      lookup_path.entries[0].methods.should == %w'undefined1 undefined2'
      lookup_path.entries[1].methods.should == %w'undefined1 undefined2'
    end

    it "should include only non-overridden public and private methods when public and private methods are requested" do
      lookup_path = Looksee::LookupPath.new(@object, :public => true, :private => true)
      lookup_path.entries[0].methods.should == %w'private1 private2 public1 public2'
      lookup_path.entries[1].methods.should == %w'private1 private2 public1 public2'
    end

    it "should include overridden methods, marked as overridden, when overridden methods are also requested" do
      lookup_path = Looksee::LookupPath.new(@object, :public => true, :overridden => true)
      lookup_path.entries[0].methods.should == %w'public1 public2'
      lookup_path.entries[1].methods.should == %w'public1 public2'
      lookup_path.entries[0].visibilities['public1'].should == :public
      lookup_path.entries[1].visibilities['public1'].should == :overridden
    end
  end

  describe "#grep" do
    before do
      temporary_class :C
      temporary_class :D
      @object = Object.new
      Looksee.stubs(:lookup_modules).with(@object).returns([C, D])
    end

    it "should only include methods matching the given regexp" do
      stub_methods(C, ['axbyc', 'xy'], [], [], [])
      stub_methods(D, ['axbyc', 'xdy'], [], [], [])
      lookup_path = Looksee::LookupPath.new(@object, :public => true, :overridden => true).grep(/x.y/)
      lookup_path.entries.map{|entry| entry.module_name}.should == %w'C D'
      lookup_path.entries[0].methods.to_set.should == Set['axbyc']
      lookup_path.entries[1].methods.to_set.should == Set['axbyc', 'xdy']
    end

    it "should only include methods including the given string" do
      stub_methods(C, ['axxa', 'axa'], [], [], [])
      stub_methods(D, ['bxxb', 'axxa'], [], [], [])
      lookup_path = Looksee::LookupPath.new(@object, :public => true, :overridden => true).grep('xx')
      lookup_path.entries.map{|entry| entry.module_name}.should == %w'C D'
      lookup_path.entries[0].methods.to_set.should == Set['axxa']
      lookup_path.entries[1].methods.to_set.should == Set['axxa', 'bxxb']
    end
  end

  describe "#inspect" do
    before do
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee.stubs(:styles).returns(Hash.new{'%s'})
    end

    describe "contents" do
      before do
        temporary_module :M
        temporary_class :C do
          include M
        end
        @object = Object.new
        Looksee.stubs(:lookup_modules).with(@object).returns([C, M])
        stub_methods(C, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
        stub_methods(M, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
      end

      it "should show singleton classes as class names in brackets" do
        Looksee.stubs(:lookup_modules).with(C).returns([C.singleton_class])
        stub_methods(C.singleton_class, ['public1', 'public2'], [], [], [])
        lookup_path = Looksee::LookupPath.new(C, :public => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |[C]
          |  public1  public2
        EOS
      end

      it "should handle singleton classes of singleton classes correctly" do
        Looksee.stubs(:lookup_modules).with(C.singleton_class).returns([C.singleton_class.singleton_class])
        stub_methods(C.singleton_class.singleton_class, ['public1', 'public2'], [], [], [])
        lookup_path = Looksee::LookupPath.new(C.singleton_class, :public => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |[[C]]
          |  public1  public2
        EOS
      end

      it "should not show any blank lines if a module has no methods" do
        stub_methods(C, [], [], [], [])
        lookup_path = Looksee::LookupPath.new(@object, :public => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |M
          |  public1  public2
        EOS
      end
    end

    describe "styles" do
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
        lookup_path = Looksee::LookupPath.new(Object.new, :public => true, :protected => true, :private => true, :undefined => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |\`C\'
          |  <private>  [protected]  {public}  ~undefined~
        EOS
      end
    end
  end
end
