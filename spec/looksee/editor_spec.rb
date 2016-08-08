require 'spec_helper'

describe Looksee::Editor do
  describe "#command_for" do
    def editor_command(command)
      Looksee::Editor.new(command).command_for('FILE', 'LINE')
    end

    it "should infer the file and line arguments for 'vi'" do
      editor_command('vi').should == ['vi', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'vim'" do
      editor_command('vim').should == ['vim', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'gvim'" do
      editor_command('gvim').should == ['gvim', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'emacs'" do
      editor_command('emacs').should == ['emacs', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'xemacs'" do
      editor_command('xemacs').should == ['xemacs', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'aquamacs'" do
      editor_command('aquamacs').should == ['aquamacs', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'pico'" do
      editor_command('pico').should == ['pico', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'nano'" do
      editor_command('nano').should == ['nano', '+LINE', 'FILE']
    end

    it "should infer the file and line arguments for 'mate'" do
      editor_command('mate').should == ['mate', '-lLINE', 'FILE']
    end

    it "should support escaped '%'-signs" do
      editor_command('%% %f %l').should == ['%', 'FILE', 'LINE']
    end

    it "should not infer file and line arguments for unknown editors" do
      editor_command('wtfbbq').should == ['wtfbbq']
    end
  end

  describe "#edit" do
    let(:tmp) { "#{ROOT}/spec/tmp" }
    let(:editor_path) { "#{tmp}/edit" }
    let(:editor_output) { "#{tmp}/edit.out" }
    let(:editor) { Looksee::Editor.new("#{editor_path} %f %l") }
    let(:editor_invocation) { File.exist?(editor_output) ? File.read(editor_output) : nil }
    let(:source_location) { ["#{tmp}/c.rb", 2] }
    let(:object) { C.new }

    before do
      FileUtils.mkdir_p tmp
      set_up_editor

      file, line = *source_location
      open(file, 'w') { |f| f.puts "class C\n  def f\n  end\nend" }
      load file
    end

    after do
      Object.send(:remove_const, :C)
      FileUtils.rm_rf tmp
    end

    def set_up_editor
      open(editor_path, 'w') { |f| f.puts <<-EOS.demargin }
        |#!/bin/sh
        |echo $# $1 $2 > "#{editor_output}"
      EOS
      File.chmod 0755, editor_path
    end

    it "should run the editor on the method's source location if available" do
      editor.edit(object, :f)
      editor_invocation.should == "2 #{source_location.join(' ')}\n"
    end

    it "should raise NoMethodError and not run the editor if the method does not exist" do
      expect { editor.edit(object, :x) }.to raise_error(Looksee::NoMethodError)
      editor_invocation.should be_nil
    end

    it "should raise NoSourceFileError and not run the editor if the source file does not exist" do
      FileUtils.rm_f source_location.first
      expect { editor.edit(object, :f) }.to raise_error(Looksee::NoSourceFileError)
      editor_invocation.should be_nil
    end

    it "should raise NoSourceLocationError and not run the editor if no source location is available" do
      UnboundMethod.any_instance.stub(source_location: nil)
      expect { editor.edit(object, :f) }.to raise_error(Looksee::NoSourceLocationError)
      editor_invocation.should be_nil
    end
  end
end
