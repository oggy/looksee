require 'spec_helper'

describe Looksee do
  describe ".[]" do
    before do
      @object = Object.new
      Looksee.stub(default_specifiers: [:public, :overridden])
    end

    it "should return an Inspector for the object's lookup path" do
      result = Looksee[@object]
      result.should be_a(Looksee::Inspector)
      result.lookup_path.object.should.equal?(@object)
    end

    it "should use Looksee.default_specifiers if no args are given" do
      Looksee[@object].visibilities.should == Set[:public, :overridden]
    end

    it "should set visibilities from the given symbols" do
      inspector = Looksee[@object, :private]
      inspector.visibilities.should == Set[:public, :overridden, :private]
    end

    it "should unset visibilities from the given 'no' symbols" do
      inspector = Looksee[@object, :nooverridden]
      inspector.visibilities.should == Set[:public]
    end

    it "should set filters from the given strings and regexp" do
      inspector = Looksee[@object, 'aa', /bb/]
      inspector.filters.should == Set['aa', /bb/]
    end

    it "should raise an ArgumentError if an invalid argument is given" do
      lambda do
        Looksee[@object, Object.new]
      end.should raise_error(ArgumentError)
    end
  end
end
