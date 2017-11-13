# frozen_string_literal: true

require "archimate"
require "graphviz"

module Archimate
  module Dsl
    # Get down to a set of relationships that will be rendered. This
    #    will get a bit more complicated than that if I support diagram only
    #    entities like notes, etc. But is good enough to start
    class View
      def initialize(model, name = "", viewpoint = :total, elements = :all, relationships = :for_elements)
        @model = model
        @name = name
        @viewpoint = viewpoint # TODO: handle reduction by viewpoint
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
        dot_model = get_positions(build_graphviz_model)

        @diagram = Archimate::DataModel::Diagram.new(
          id: @model.make_unique_id,
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
            DataModel::Connection.new(
              id: @model.make_unique_id,
              diagram: @diagram,
              relationship: node.relationship,
              bendpoints: node.bendpoints.map { |bp|
                DataModel::Location.new(
                  x: bp.x - source.bounds.x,
                  y: bp.y - source.bounds.y,
                  end_x: bp.x - target.bounds.x,
                  end_y: bp.y - target.bounds.y
                )
              },
              source: source,
              target: viewnode_for(node.target),
              type: "archimate:Connection" # TODO: This is archi-centric. Needs to change to concrete object types
            )
          end
      end

      def build_graphviz_model
        g = GraphViz.new( :G, :type => :digraph )
        g.node["fixedsize"] = "true"
        g.node["width"] = 1.0
        g.node["height"] = 0.5
        g.node["shape"] = "box"
        g.edge["dir"] = "none"
        g.edge["headclip"] = "false"
        g.edge["tailclip"] = "false"
        g["splines"] = "ortho"
        g["rankdir"] = "BT"

        elements = @relationships.map { |rel| [rel.source, rel.target] }.flatten.uniq

        node_map = elements.each_with_object({}) do |el, hash|
          hash[el] = g.add_nodes(el.id, id: el.id, label: el.name)
        end

        @relationships.each do |rel|
          g.add_edges(node_map[rel.source], node_map[rel.target], label: rel.id)
        end
        g
      end

      GVNode = Struct.new(:element, :x, :y, :width, :height)
      GVEdge = Struct.new(:relationship, :source, :target, :bendpoints)

      def element_by_id(id)
        id = id.tr('"', '')
        @elements.find { |el| el.id == id }
      end

      def relationship_by_id(id)
        id = id.tr('"', '')
        @relationships.find { |rel| rel.id == id }
      end

      def get_positions(g)
        str = g.output(:plain => String)
        positions = str.each_line.map(&:split).map do |cols|
          case cols.shift
          when "graph"
            # graph scale width height
            @scale, @width, @height = cols.map(&:to_f)
            @width *= 110.0
            @height *= 110.0
            nil
          when "node"
            # node name x y width height label style shape color fillcolor
            id, x, y, width, height = cols
            GVNode.new(element_by_id(id), x.to_f * 110, @height - y.to_f * 110, width.to_f * 110, height.to_f * 110)
          when "edge"
            # edge tail head n x1 y1 .. xn yn [label xl yl] style color
            source_id, target_id, point_count = cols
            point_count = point_count.to_i
            points = cols.slice(3, 2 * point_count)
            id = cols[3 + 2 * point_count]
            GVEdge.new(
              relationship_by_id(id),
              element_by_id(source_id),
              element_by_id(target_id),
              make_bendpoints(points.map(&:to_f))
            )
          end
        end
        positions.compact
      end

      def make_bendpoints(points)
        bps = []
        points.each_slice(2) { |xy| bps << xy }
        bps.uniq.reverse.slice(1..-2).map { |xy| DataModel::Location.new(x: xy[0] * 110, y: @height - xy[1] * 110) }
      end
    end
  end
end
