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

    context "when #ls is renamed" do
      before { Looksee.rename(:ls2) }
      after { Looksee.rename(:ls) }

      it "should honor the new name" do
        @object.ls2.should be_a(Looksee::Inspector)
        expect { @object.ls }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#respond_to_missing?" do
    it "should be true for :ls" do
      @object.__send__(:respond_to_missing?, :ls).should == true
    end

    context "when #ls renamed" do
      before { Looksee.rename(:ls2) }
      after { Looksee.rename(:ls) }

      it "should honor the new name" do
        @object.__send__(:respond_to_missing?, :ls2).should == true
        @object.__send__(:respond_to_missing?, :ls).should == false
      end
    end
  end
end
