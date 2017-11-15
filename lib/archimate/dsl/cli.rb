# frozen_string_literal: true

require 'optparse'

module Archimate
  module Dsl
    class Cli
      Options = Struct.new(:outfile, :format, :infile, :views_dir)

      class Parser
        def self.parse(options)
          args = Options.new("model.archimate", "archimate", $stdin, ".")

          opt_parser = OptionParser.new do |opts|
            opts.banner = "Usage: archidsl [options] ARX_FILE"

            opts.on("-oFILENAME", "--outfile=FILENAME", "Filename to write ArchiMate model") do |n|
              args.outfile = n
            end

            opts.on("-fFORMAT", "--format=FORMAT", "Format to write file. Defaults to extension of FILENAME") do |f|
              args.format = f
            end

            opts.on("-sDIR", "--svg=DIR", "Export the views SVGs from this model") do |s|
              args.views_dir = s
            end

            opts.on("-h", "--help", "Prints this help") do
              puts opts
              exit
            end
          end

          opt_parser.parse!(options)
          args[:infile] = opt_parser.default_argv if opt_parser.default_argv
          args
        end
      end

      def self.start(argv)
        new.start(argv)
      end

      def start(argv)
        options = Parser.parse(argv)
        template = Dsl::Template.new(File.read(options.infile.first))
        model = template.render
        File.open(options.outfile, "wb") do |io|
          FileFormats::ArchiFileWriter.new(model.organize).write(io)
        end
        model.diagrams.each do |diagram|
          File.open(File.join(options.views_dir, "#{diagram.name}.svg"), "wb") do |svg_file|
            svg_file.write(Svg::Diagram.new(diagram).to_svg)
          end
        end
      end
    end
  end
end
