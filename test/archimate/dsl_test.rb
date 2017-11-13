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

          app_portal_interface = application_interface "portal interface"
          app.composes(app_portal_interface)

          view "Everything"
        end
      TEMPLATE

      input = {
        name: "Archisurance",
        version: "3.1.1",
        documentation: "An example of a fictional Insurance company."
      }
      model = template.render(input)

      assert_kind_of Archimate::DataModel::Model, model
      assert_equal input[:name], model.name.to_s
      assert_equal input[:documentation], model.documentation.to_s
      assert_equal input[:version], model.version
      assert_equal 6, model.elements.size
      assert_equal "email", model.elements.first.name
      assert_kind_of Archimate::DataModel::Elements::BusinessInterface, model.elements.first

      assert_equal 5, model.relationships.size

      assert_equal 1, model.diagrams.size
      dia = model.diagrams.first
      assert_equal "Everything", dia.name.to_s

      model.relationships.each do |rel|
        refute_nil rel.source
        refute_nil rel.source.id
        refute_nil rel.target
        refute_nil rel.target.id
      end
      model.organize
      model.relationships.each do |rel|
        refute_nil rel.source
        refute_nil rel.source.id
        refute_nil rel.target
        refute_nil rel.target.id
      end

      File.open("dsl-archi.archimate", "wb") do |io|
        FileFormats::ArchiFileWriter.new(model.organize).write(io)
      end

      File.open("dsl-diagram.svg", "wb") do |svg_file|
        svg_file.write(Svg::Diagram.new(model.diagrams.first).to_svg)
      end
    end
  end
end
