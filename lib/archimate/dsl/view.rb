# frozen_string_literal: true

require "archimate"

module Archimate
  module Dsl
    # Get down to a set of relationships that will be rendered. This
    #    will get a bit more complicated than that if I support diagram only
    #    entities like notes, etc. But is good enough to start
    class View
      def initialize(model, name = "", id = nil, viewpoint = :total, elements = :all, relationships = :for_elements)
        @model = model
        @name = name
        @viewpoint = viewpoint # TODO: handle reduction by viewpoint
        @id = id
        @elements = elements == :all ? model.elements : elements
        @relationships =
          case relationships
          when :all
            model.relationships
          when :for_elements
            model.relationships.select do |relationship|
              @elements.include?(relationship.source) && @elements.include?(relationship.target)
            end
          else
            relationships
          end
        return if @viewpoint == :total
        @elements = @viewpoint.select_elements(@elements)
        @relationships =
          @viewpoint
          .select_relationships(@relationships)
          .select { |relationship| @elements.include?(relationship.source) && @elements.include?(relationship.target) }
      end

      # 2. Build graphviz model for those entities. Start with a fixed size, then
      #    ultimately ask the SVG engine to determine the size for the entity.
      # 3. Get the graphviz render positions for the graph
      # 4. Iterate over the render positions creating a set of ViewNodes and
      #    Connections for the graph.
      # 5. Wrap up into a diagram
      # 6. Return the diagram.
      def render
        dot_model = ViewLayout.new(@elements, @relationships).positions # get_positions(build_graphviz_model)

        @diagram = Archimate::DataModel::Diagram.new(
          id: @id || @model.make_unique_id,
          name: DataModel::LangString.string(@name)
        )
        @diagram.nodes = view_nodes_for(dot_model)
        @diagram.connections = connections_for(dot_model)
        @diagram
      end

      def view_nodes_for(dot_model)
        @element_view_node = {}
        dot_model
          .select { |item| item.is_a?(GVNode) }
          .map do |node|
            view_node = DataModel::ViewNode.new(
              id: @model.make_unique_id,
              diagram: @diagram,
              element: node.element,
              bounds: DataModel::Bounds.new(x: node.x, y: node.y, width: node.width, height: node.height),
              type: "archimate:DiagramObject" # TODO: This is archi-centric. Needs to change to concrete object types
            )
            @element_view_node[node.element] = view_node
            view_node
          end
      end

      def viewnode_for(element)
        @element_view_node[element]
      end

      def connections_for(dot_model)
        dot_model
          .select { |item| item.is_a?(GVEdge) }
          .map do |node|
            source = viewnode_for(node.source)
            target = viewnode_for(node.target)
            bendpoints =
              node
              .bendpoints.map { |bp| DataModel::Location.new(x: bp.x, y: bp.y) }
              .delete_if { |bp| bp.inside?(source.bounds) || bp.inside?(target.bounds) }
            DataModel::Connection.new(
              id: @model.make_unique_id,
              diagram: @diagram,
              relationship: node.relationship,
              bendpoints: bendpoints,
              source: source,
              target: target,
              type: "archimate:Connection" # TODO: This is archi-centric. Needs to change to concrete object types
            )
          end
      end
    end
  end
end
