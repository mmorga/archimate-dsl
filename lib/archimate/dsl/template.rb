# frozen_string_literal: true

module Archimate
  module Dsl
    class Template
      def self.from_file(path)
        new(File.read(path), path)
      end

      def initialize(arx_source, filename = '(arx)', lineno = 1)
        @block = CleanBinding.get.eval(<<-SOURCE, filename, lineno - 1)
          Proc.new do
            #{arx_source}
          end
        SOURCE
      end

      def render(instance_variables = {})
        dsl = Arx.new

        instance_variables.each do |name, value|
          dsl.instance_variable_set("@#{name}", value)
        end

        dsl.instance_eval(&@block)

        dsl.__model
      end

      module CleanBinding
        def self.get
          binding
        end
      end
    end
  end
end
