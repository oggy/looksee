require 'spec_helper'

describe Looksee::WirbleCompatibility do
  describe "when looksee is loaded" do
    #
    # Run the given ruby string, and return the standard output.
    #
    def init_irb_with(code)
      code = <<-EOS.demargin
        |#{code}
        |#{setup_code}
        |c.ls
      EOS
      code = code.chomp.gsub(/\n/, ';') # only print value of last line
      irb = File.join Config::CONFIG['bindir'], 'irb'
      lib_dir = File.expand_path('lib')
      # irb hangs when using readline without a tty
      output = IO.popen("bundle exec #{irb} -f --noreadline --noprompt --noverbose -I#{lib_dir} 2>&1", 'r+') do |io|
        io.puts code
        io.flush
        io.close_write
        io.read
      end
      # Ruby 1.9.2 prints an extra newline on exit.
      output.chomp! if RUBY_VERSION >= '1.9.2'
      output
    end

    def setup_code
      <<-EOS.demargin
        |C = Class.new
        |c = C.new
        |#{File.read('spec/support/test_adapter.rb')}
        |
        |Looksee.styles = Hash.new{'%s'}
        |Looksee.styles[:public] = "\\e[1;32m%s\\e[0m"
        |NATIVE_ADAPTER = Looksee.adapter
        |Looksee.adapter = TestAdapter.new
        |Looksee.adapter.ancestors[c] = [C]
        |Looksee.adapter.public_methods[C] = [:a]
      EOS
    end

    it "should work if wirble is not loaded" do
      output = init_irb_with(<<-EOS.demargin)
        |require 'irb'
        |require 'looksee'
        |require 'wirble'
        |Wirble.init
        |Wirble.colorize
      EOS
      output.should == <<-EOS.demargin
        |C
        |  \e[1;32ma\e[0m
      EOS
    end

    it "should work if wirble is loaded, but not initialized" do
      output = init_irb_with(<<-EOS.demargin)
        |require 'irb'
        |require 'wirble'
        |require 'looksee'
        |Wirble.init
        |Wirble.colorize
      EOS
      output.should == <<-EOS.demargin
        |C
        |  \e[1;32ma\e[0m
      EOS
    end

    it "should work if wirble is loaded and initialized, but colorizing is off" do
      output = init_irb_with(<<-EOS.demargin)
        |require 'irb'
        |require 'wirble'
        |Wirble.init
        |require 'looksee'
        |Wirble.colorize
      EOS
      output.should == <<-EOS.demargin
        |C
        |  \e[1;32ma\e[0m
      EOS
    end

    it "should work if wirble is loaded, initialized, and colorizing is on" do
      output = init_irb_with(<<-EOS.demargin)
        |require 'irb'
        |require 'wirble'
        |Wirble.init
        |Wirble.colorize
        |require 'looksee'
      EOS
      output.should == <<-EOS.demargin
        |C
        |  \e[1;32ma\e[0m
      EOS
    end

    it "should work if wirble colorizing is enabled twice" do
      output = init_irb_with(<<-EOS.demargin)
        |require 'irb'
        |require 'looksee'
        |require 'wirble'
        |Wirble.init
        |Wirble.colorize
        |Wirble.colorize
      EOS
      output.should == <<-EOS.demargin
        |C
        |  \e[1;32ma\e[0m
      EOS
    end
  end
end
