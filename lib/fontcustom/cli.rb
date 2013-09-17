require "thor"
require "thor/actions"
require "fontcustom"
require "fontcustom/watcher"

module Fontcustom
  class CLI < Thor
    include Thor::Actions

    default_task :show_help

    class_option :project_root, :aliases => "-r", :type => :string,
      :desc => "The root context for any relative paths (INPUT, OUTPUT, CONFIG).",
      :default => EXAMPLE_OPTIONS[:project_root]

    class_option :output, :aliases => "-o", :type => :string,
      :desc => "Where generated files are saved. Can be fine-tuned if a configuration file is used.",
      :default => EXAMPLE_OPTIONS[:output]

    class_option :config, :aliases => "-c", :type => :string,
      :desc => "Optional configuration file. PROJECT_ROOT/fontcustom.yml and PROJECT_ROOT/config/fontcustom.yml are loaded automatically."

    class_option :data_cache, :aliases => "-d", :type => :string,
      :desc => "Optional path to `.fontcustom-data`. Used for garbage collection."

    class_option :templates, :aliases => "-t", :type => :array,
      :desc => "Space-delinated array of templates to generate alongside fonts.",
      :enum => %w|preview css scss scss-rails bootstrap bootstrap-scss bootstrap-ie7 bootstrap-ie7-scss|,
      :default => DEFAULT_OPTIONS[:templates]

    class_option :font_name, :aliases => "-f", :type => :string,
      :desc => "Set the font's name.",
      :default => DEFAULT_OPTIONS[:font_name]

    class_option :css_prefix, :aliases => "-p", :type => :string,
      :desc => "Prefix for each glyph's CSS class.",
      :default => DEFAULT_OPTIONS[:css_prefix]

    class_option :preprocessor_path, :aliases => "-s", :type => :string,
      :desc => "Font path used in CSS proprocessor templates."

    class_option :no_hash, :aliases => "-h", :type => :boolean,
      :desc => "Generate fonts without asset-busting hashes.",
      :default => DEFAULT_OPTIONS[:no_hash]

    class_option :debug, :aliases => "-g", :type => :boolean,
      :desc => "Display debugging messages.",
      :default => DEFAULT_OPTIONS[:debug]

    class_option :quiet, :aliases => "-q", :type => :boolean,
      :desc => "Hide status messages.",
      :default => DEFAULT_OPTIONS[:quiet]

    # Required for Thor::Actions#template
    def self.source_root
      File.join Fontcustom.gem_lib, "templates"
    end

    desc "compile [INPUT] [OPTIONS]", "Generates webfonts and templates from *.svg and *.eps files in INPUT. Default: `pwd`"
    def compile(input = nil)
      opts = options.merge :input => input
      opts = Options.new(opts)
      Generator::Font.start [opts]
      Generator::Template.start [opts]
    rescue Fontcustom::Error => e
      opts.say_message :error, e.message, :red
    end

    desc "watch [INPUT] [OPTIONS]", "Watches INPUT for changes and regenerates files automatically. Ctrl + C to stop. Default: `pwd`"
    method_option :skip_first, :type => :boolean,
      :desc => "Skip the initial compile upon watching.",
      :default => false
    def watch(input = nil)
      say "Font Custom is watching your icons. Press Ctrl + C to stop.", :yellow unless options[:quiet]
      opts = options.merge :input => input, :skip_first => !! options[:skip_first]
      opts = Options.new(opts)
      Watcher.new(opts).watch
    rescue Fontcustom::Error => e
      opts.say_message :error, e.message, :red
    end

    desc "config [DIR]", "Generates an annotated configuration file (fontcustom.yml) in DIR. Default: `pwd`"
    def config(dir = Dir.pwd)
      template "fontcustom.yml", File.join(dir, "fontcustom.yml")
    end

    desc "hidden", "hidden", :hide => true
    method_option :version, :aliases => "-v", :type => :boolean, :default => false
    def show_help
      if options[:version]
        puts "fontcustom-#{VERSION}"
      else
        help
      end
    end
  end
end
