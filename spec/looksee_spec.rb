require 'spec'
require 'mocha'
require 'looksee'

class Object
  #
  # Return this object's singleton class.
  #
  def singleton_class
    class << self; self; end
  end
end

class String
  #
  # Remove a left margin delimited by '|'-characters.  Useful for
  # heredocs:
  #
  def demargin
    gsub(/^ *\|/, '')
  end
end

class Base
  public
  def base_public; end
  protected
  def base_protected; end
  private
  def base_private; end

  class << self
    public
    def base_singleton_public; end
    protected
    def base_singleton_protected; end
    private
    def base_singleton_private; end
  end
end

module Mod1
  public
  def mod1_public; end
  protected
  def mod1_protected; end
  private
  def mod1_private; end

  class << self
    public
    def mod1_singleton_public; end
    protected
    def mod1_singleton_protected; end
    private
    def mod1_singleton_private; end
  end
end

module Mod2
  public
  def mod2_public; end
  protected
  def mod2_protected; end
  private
  def mod2_private; end

  class << self
    public
    def mod2_singleton_public; end
    protected
    def mod2_singleton_protected; end
    private
    def mod2_singleton_private; end
  end
end

class Derived < Base
  include Mod1
  include Mod2

  public
  def derived_public; end
  protected
  def derived_protected; end
  private
  def derived_private; end

  class << self
    public
    def derived_singleton_public; end
    protected
    def derived_singleton_protected; end
    private
    def derived_singleton_private; end
  end
end

describe Looksee do
  describe ".looksee" do
    it "should return a LookupPath containing the modules in the lookup path of the object" do
      path = Looksee.looksee(Derived.new)
      path.should be_a(Looksee::LookupPath)
      # Beyond the first 5 modules are RSpec modules, Mocha modules,
      # BasicObject in 1.9, and possibly other junk...
      path.modules.first(5).should == [Derived, Mod2, Mod1, Base, Object]
    end

    it "should work for a singleton class too" do
      path = Looksee.looksee(Derived)
      path.should be_a(Looksee::LookupPath)
      path.modules.first(4).should == [
        Derived.singleton_class, Base.singleton_class, Object.singleton_class, Class
      ]
    end
  end
end

describe Looksee::LookupPath do
  before do
    Looksee.default_options = {}
  end

  def stub_methods(mod, public, protected, private)
    mod.stubs(:public_instance_methods   ).returns(public)
    mod.stubs(:protected_instance_methods).returns(protected)
    mod.stubs(:private_instance_methods  ).returns(private)
  end

  describe "#initialize" do
    it "should take extra symbol arguments as true options" do
      Looksee::LookupPath.new([], :public, :shadowed).options.should ==
        {:public => true, :shadowed => true}
    end

    it "should merge the default options, with the symbols, and the options hash" do
      Looksee.stubs(:default_options).returns({:public => false, :protected => false, :private => false})
      Looksee::LookupPath.new([], :protected, :private, {:private => false}).options.should ==
        {:public => false, :protected => true, :private => false}
    end
  end

  describe "#inspect" do
    before do
      Looksee.stubs(:styles).returns(Hash.new{'%s'})
    end

    describe "contents" do
      before do
        [Derived, Mod1, Base].each do |mod|
          stub_methods(mod, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'])
        end
      end

      it "should show only public instance methods when only public methods are requested" do
        lookup_path = Looksee::LookupPath.new([Derived, Mod1, Base], :public, :shadowed)
        lookup_path.inspect.should == <<-EOS.demargin
          |Derived
          |  public1  public2
          |Mod1
          |  public1  public2
          |Base
          |  public1  public2
        EOS
      end

      it "should show modules and protected instance methods when only protected methods are requested" do
        lookup_path = Looksee::LookupPath.new([Derived, Mod1, Base], :protected, :shadowed)
        lookup_path.inspect.should == <<-EOS.demargin
          |Derived
          |  protected1  protected2
          |Mod1
          |  protected1  protected2
          |Base
          |  protected1  protected2
        EOS
      end

      it "should show modules and private instance methods when only private methods are requested" do
        lookup_path = Looksee::LookupPath.new([Derived, Mod1, Base], :private, :shadowed)
        lookup_path.inspect.should == <<-EOS.demargin
          |Derived
          |  private1  private2
          |Mod1
          |  private1  private2
          |Base
          |  private1  private2
        EOS
      end

      it "should show modules with public and private instance methods when only public and private methods are requested" do
        lookup_path = Looksee::LookupPath.new([Derived, Mod1, Base], :public, :private, :shadowed)
        lookup_path.inspect.should == <<-EOS.demargin
          |Derived
          |  private1  private2  public1  public2
          |Mod1
          |  private1  private2  public1  public2
          |Base
          |  private1  private2  public1  public2
        EOS
      end

      it "should show singleton classes as class names in brackets" do
        lookup_path = Looksee::LookupPath.new([Derived.singleton_class], :public)
        stub_methods(Derived.singleton_class, ['public1', 'public2'], [], [])
        lookup_path.inspect.should == <<-EOS.demargin
          |[Derived]
          |  public1  public2
        EOS
      end

      it "should handle singleton classes of singleton classes correctly" do
        lookup_path = Looksee::LookupPath.new([Derived.singleton_class.singleton_class], :public)
        stub_methods(Derived.singleton_class.singleton_class, ['public1', 'public2'], [], [])
        lookup_path.inspect.should == <<-EOS.demargin
          |[[Derived]]
          |  public1  public2
        EOS
      end
    end

    describe "styles" do
      before do
        styles = {
          :module    => "`%s'",
          :public    => "{%s}",
          :protected => "[%s]",
          :private   => "<%s>",
          :shadowed  => "(%s)",
        }
        Looksee.stubs(:styles).returns(styles)
      end

      it "should delimit each word with the configured delimiters" do
        stub_methods(Derived, ['public'], ['protected'], ['private'])
        stub_methods(Base, ['public', 'foo'], [], [])
        Looksee::LookupPath.new([Derived, Base], :public, :protected, :private, :shadowed).inspect.should == <<-EOS.demargin
          |\`Derived\'
          |  <private>  [protected]  {public}
          |\`Base\'
          |  {foo}  (public)
        EOS
      end
    end

    describe "layout" do
      it "should wrap method lists at the configured number of columns, sorting vertically first, and aligning into a grid" do
        lookup_path = Looksee::LookupPath.new([Base], :public)
        stub_methods(Base, %w'aa b c dd ee f g hh i', [], [])
        lookup_path.inspect(:width => 20).should == <<-EOS.demargin
          |Base
          |  aa  c   ee  g   i
          |  b   dd  f   hh
        EOS
      end

      it "should lay the methods of each module out independently" do
        stub_methods(Derived, ['a', 'long_long_long_long_name'], [], [])
        stub_methods(Base, ['long_long_long', 'short'], [], [])
        lookup_path = Looksee::LookupPath.new([Derived, Base], :public)
        lookup_path.inspect.should == <<-EOS.demargin
          |Derived
          |  a  long_long_long_long_name
          |Base
          |  long_long_long  short
        EOS
      end
    end
  end
end
