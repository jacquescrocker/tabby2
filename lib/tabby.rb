require "erb"
require "tempfile"
require "ostruct"

module Tabby
  class Base
    class << self
      attr_reader :_basedir
    
      def basedir(dir)
        @_basedir = dir
      end
    end

    # List of commands for the current tab being created.
    attr_accessor :commands

    # Title of the current tab being created.
    attr_accessor :title

    # Rendered AppleScript source to be saved to a tempfile.
    attr_accessor :template

    def initialize
      @commands = []
    end

    # Queue a command to be executed when the tab gets created.
    # 
    # Parameters:
    #   command   bash/zsh/etc command to be executed
    #
    def exec(command)
      @commands << %{write text "#{command}"}
    end

    # Call each instance method and create a tab for each one.
    # Method names become tab titles, with underscores replaced
    # with spaces.
    #
    def call
      self.class.instance_methods(false).each do |method|
        @commands = []
        @title    = method
        send(method)
        create_tab
      end
    end

    # Project's base directory. Each tab +cd+'s into this
    # directory before executing commands.
    #
    def basedir
      self.class._basedir
    end
  
  private

    def create_tab
      source   = render_script
      tempfile = Tempfile.new("tabby-#{@title}")
      tempfile.write(render_script)
      tempfile.close
      Kernel.system("osascript #{tempfile.path}")
    end
  
    def render_script
      osapath   = File.expand_path("../../script/tabby.osa.erb", __FILE__)
      template  = ERB.new(File.read(osapath))
      commands  = @commands.join("\n")
      @template = template.result(binding)
    end
  end
end
