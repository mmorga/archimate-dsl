# frozen_string_literal: true

require "test_helper"

module Archimate
  class DslTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Archimate::Dsl::VERSION
    end

    def test_template_produces_a_model
      template = Dsl::Template.new(<<~'TEMPLATE')
        model(
          @name,
          version: @version,
          documentation: @documentation
        ) do |model|
          business_interface "email"
          app_api = application_interface "app api"
          app = application_component "app"
          app_svc = application_service "app svc"
          app_func = application_function "app func"

          composition source: app, target: app_api
          assignment source: app_api, target: app_svc
          assignment source: app, target: app_func
          realization source: app_func, target: app_svc
        end
      TEMPLATE

      input = {
        name: "Archisurance",
        version: "3.1.1",
        documentation: "An example of a fictional Insurance company."
      }
      model = template.render(input)

      assert_kind_of Archimate::DataModel::Model, model
      assert_equal input[:name], model.name
      assert_equal input[:documentation], model.documentation
      assert_equal input[:version], model.version
      assert_equal 5, model.elements.size
      assert_equal "email", model.elements.first.name
      assert_kind_of Archimate::DataModel::Elements::BusinessInterface, model.elements.first

      assert_equal 4, model.relationships.size
    end
  end
end
