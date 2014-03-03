require 'spec_helper'

describe Looksee::ObjectMixin do
  describe "#ls" do
    before do
      @object = Object.new
      Looksee.stub(:default_specifiers).and_return([])
    end

    it "should return an Inspector for the object's lookup path using the given arguments" do
      result = @object.ls(:private)
      result.should be_a(Looksee::Inspector)
      result.lookup_path.object.should.equal?(@object)
      result.visibilities.should == Set[:private]
    end
  end
end
