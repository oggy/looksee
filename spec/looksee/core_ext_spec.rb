require 'spec_helper'

describe Looksee::ObjectMixin do
  before do
    @object = Object.new
    Looksee.stub(:default_specifiers).and_return([])
  end

  describe "#ls" do
    it "should return an Inspector for the object's lookup path using the given arguments" do
      result = @object.ls(:private)
      result.should be_a(Looksee::Inspector)
      result.lookup_path.object.should.equal?(@object)
      result.visibilities.should == Set[:private]
    end
  end

  describe '.rename' do
    it 'renames the name of the mixin' do
      Looksee::ObjectMixin.rename(:lp)
      @object.should_not respond_to(:ls)
      expect{ @object.ls }.to raise_error(NoMethodError)
      @object.should respond_to(:lp)
      result = @object.lp
      result.should be_a(Looksee::Inspector)
    end
  end
end
