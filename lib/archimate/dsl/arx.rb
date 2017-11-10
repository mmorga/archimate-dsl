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

      def model(name = "", attrs = {}, &block)
        attrs[:name] = name unless attrs.key?(:name)
        attrs[:id] = "arxmodel" unless attrs.key?(:id)
        @__model = Archimate::DataModel::Model.new(attrs)
        # @__model.instance_eval(&block) # If you want to yield a new binding, this is how
        yield __model
        __model
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
            @__model.elements << el
            yield el if block_given?
            el
          end
        end

      Archimate::DataModel::Relationships
        .constants
        .each do |cls_sym|
          method_name = cls_sym.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
          define_method(method_name) do |name = "", attrs = {}|
            raise "Must be in the context of a model" unless __model
            attrs[:name] = name unless attrs.key?(:name)
            attrs[:id] = __model.send(:random_id) unless attrs.key?(:id)
            rel = Archimate::DataModel::Relationships.const_get(cls_sym).new(attrs)
            @__model.relationships << rel
            yield rel if block_given?
            rel
          end
        end
    end
  end
end
