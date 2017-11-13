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

      def model(name = "", attrs = {})
        attrs[:name] = name unless attrs.key?(:name)
        attrs[:id] = "arxmodel" unless attrs.key?(:id)
        attrs[:name] = DataModel::LangString.string(attrs[:name])
        attrs[:documentation] = DataModel::LangString.string(attrs[:documentation])
        @__model = Archimate::DataModel::Model.new(attrs)
        yield __model
        __model
      end

      # So here's what view will do
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

      Archimate::DataModel::Elements
        .constants
        .each do |cls_sym|
          method_name = cls_sym.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
          define_method(method_name) do |name, attrs = {}|
            raise "Must be in the context of a model" unless __model
            attrs[:name] = name unless attrs.key?(:name)
            attrs[:id] = __model.send(:random_id) unless attrs.key?(:id)
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
            attrs[:name] = DataModel::LangString.new(attrs[:name]) if attrs[:name]
            attrs[:documentation] = DataModel::LangString.new(attrs[:documentation]) if attrs[:documentation]
            attrs[:name] = name unless attrs.key?(:name)
            attrs[:id] = __model.send(:random_id) unless attrs.key?(:id)
            rel = Archimate::DataModel::Relationships.const_get(cls_sym).new(attrs)
            __model.relationships << rel
            yield rel if block_given?
            rel
          end
        end
    end
  end
end
