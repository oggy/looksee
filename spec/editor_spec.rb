require 'spec_helper'

describe Looksee::Editor do
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

  describe "#edit" do
    TMP = "#{ROOT}/spec/tmp"

    before do
      FileUtils.mkdir_p TMP
      make_editor "#{TMP}/edit"
      @editor = Looksee::Editor.new("#{TMP}/edit %f %l")
    end

    after do
      FileUtils.rm_rf TMP
    end

    def make_editor(path)
      open(path, 'w') { |f| f.puts <<-EOS.demargin }
        |#!/bin/sh
        |echo $# $1 $2 > "#{TMP}/editor.out"
      EOS
      File.chmod 0755, path
    end

    def with_source_file
      path = "#{TMP}/c.rb"
      open(path, 'w') { |f| f.puts <<-EOS.demargin }
        |class C
        |  def f
        |  end
        |end
      EOS
      begin
        load path
        Looksee.adapter.set_methods(C, [:f], [], [], [])
        yield path
      ensure
        Object.send(:remove_const, :C)
      end
    end

    it "should run the editor on the method's source location if available" do
      with_source_file do |path|
        c = C.new
        Looksee.adapter.ancestors[c] = [C, Object]
        Looksee.adapter.set_source_location(C, :f, [path, 2])
        @editor.edit(c, :f)
        File.read("#{TMP}/editor.out").should == "2 #{path} 2\n"
      end
    end

    it "should not run the editor if the source file does not exist" do
      with_source_file do |path|
        FileUtils.rm_f path
        @editor.edit(C.new, :f)
        File.should_not exist("#{TMP}/editor.out")
      end
    end

    it "should not run the editor for methods defined with eval where no source file specified" do
      eval <<-EOS.demargin
        |class ::C
        |  def f
        |  end
        |end
      EOS
      begin
        @editor.edit(C.new, :f)
        File.should_not exist("#{TMP}/editor.out")
      ensure
        Object.send(:remove_const, :C)
      end
    end

    it "should not run the editor for primitives" do
      @editor.edit('', :size)
      File.should_not exist("#{TMP}/editor.out")
    end
  end
end
