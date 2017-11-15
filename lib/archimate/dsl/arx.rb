# frozen_string_literal: true

require "archimate"

module Archimate
  module Dsl
    class Arx
      attr_reader :__model

      def initialize
        @__model = nil
        @__element_stack = [@__root]
      end

      def include(file)
        instance_eval(File.read(file), file, 1)
      end

      def model(name = "", attrs = {})
        attrs[:name] = name unless attrs.key?(:name)
        attrs[:id] = "arxmodel" unless attrs.key?(:id)
        attrs[:name] = DataModel::LangString.string(attrs[:name])
        attrs[:documentation] = DataModel::LangString.string(attrs[:documentation])
        @__model = Archimate::DataModel::Model.new(attrs)
        yield __model
        __model
      end

      # So here's what view does
      # It will produce an ArchiMate view with the argument criteria
      # What is included is based on the criteria for the Viewpoint
      # specified, and a sum of:
      #
      # * Elements specified in `elements` - elements not referenced by
      #   Relationships specified by `relationships`
      # * Relationships specified in `relationships`
      #   - specified list
      #   - `:for_elements`: only includes relationships with `source` and
      #     `target` in the `elements` argument
      #   - `:all`: all relationships in the model
      #
      # Selected elements and relationships are reduced by the elements
      # and relationships that are valid for the specified viewpoint.
      #
      # @param name [String] Name of the resulting diagram
      # @param viewpoint [String, Viewpoint] Name of built in Viewpoint or
      #        Viewpoint instance describing the view. Default is a total
      #        viewpoint allowing any elements and relationships
      # @param elements [Array<Element>, :all] List of elements to include in
      #        view or `:all` to include all (default `:all`)
      # @param relationships [Array<Relationship>, :for_elements, :all] List of
      #        relationships to include in view, `:for_elements` or `:all` to
      #        include all (default `:for_elements`)
      def view(name = "", viewpoint: :total, elements: :all, relationships: :for_elements)
        __model.diagrams << View.new(__model, name, viewpoint, elements, relationships).render
      end

      def properties(args)
        args.map do |k, v|
          pd = __model.property_definitions.find { |prop_def| prop_def.name.to_s == k }
          if pd.nil?
            pd = DataModel::PropertyDefinition.new(id: __model.make_unique_id, name: DataModel::LangString.new(k))
            __model.property_definitions << pd
          end
          __model.properties << DataModel::Property.new(property_definition: pd, value: DataModel::LangString.new(v))
        end
      end

      # def folder(name, id: nil, type: nil, &block)
      #   folder = DataModel::Organization.new(id: id, name: DataModel::LangString.new(name), type: type)
      #   __model.organizations << folder
      #   return folder unless block_given?
      #   dsl = ArxFolder.new(__model, folder)
      #   dsl.instance_eval(&block)
      #   folder
      # end

      Archimate::DataModel::Viewpoints.constants.each do |sym|
        method_name = "#{sym.to_s.downcase}_viewpoint".to_sym
        define_method(method_name) do
          Archimate::DataModel::Viewpoints.const_get(sym, false)
        end
      end

      Archimate::DataModel::Elements
        .constants
        .each do |cls_sym|
          method_name = cls_sym.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
          define_method(method_name) do |name = nil, attrs = {}|
            raise "Must be in the context of a model" unless __model
            if name.is_a?(Hash) && attrs.empty?
              attrs = name
              name = attrs.fetch(:name, nil)
            end
            attrs[:name] = name unless attrs.key?(:name)
            attrs[:id] = __model.make_unique_id unless attrs.key?(:id)
            attrs[:name] = DataModel::LangString.new(attrs[:name]) if attrs[:name]
            attrs[:documentation] = DataModel::LangString.new(attrs[:documentation]) if attrs[:documentation]
            el = Archimate::DataModel::Elements.const_get(cls_sym).new(attrs)
            __model.elements << el
            yield el if block_given?
            el
          end
        end

      Archimate::DataModel::Relationships
        .constants
        .each do |cls_sym|
          method_name = cls_sym.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
          define_method(method_name) do |name = nil, attrs = {}|
            raise "Must be in the context of a model" unless __model
            if name.is_a?(Hash) && attrs.empty?
              attrs = name
              name = attrs.fetch(:name, nil)
            end
            attrs[:name] = name unless attrs.key?(:name)
            attrs[:id] = __model.make_unique_id unless attrs.key?(:id)
            attrs[:name] = DataModel::LangString.new(attrs[:name]) if attrs[:name]
            attrs[:documentation] = DataModel::LangString.new(attrs[:documentation]) if attrs[:documentation]
            rel = Archimate::DataModel::Relationships.const_get(cls_sym).new(attrs)
            __model.relationships << rel
            yield rel if block_given?
            rel
          end
        end
    end
  end
end
