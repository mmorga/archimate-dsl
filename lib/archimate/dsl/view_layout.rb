# frozen_string_literal: true

require "archimate"
require "graphviz"

module Archimate
  module Dsl
    GVNode = Struct.new(:element, :x, :y, :width, :height)
    GVEdge = Struct.new(:relationship, :source, :target, :bendpoints)
    # Get down to a set of relationships that will be rendered. This
    #    will get a bit more complicated than that if I support diagram only
    #    entities like notes, etc. But is good enough to start
    class ViewLayout
      SCALE_FACTOR = 110

      attr_reader :g
      attr_reader :width
      attr_reader :height
      attr_reader :elements
      attr_reader :relationships

      def initialize(elements, relationships)
        @g = nil
        @relationships = relationships
        @elements = elements
      end

      def positions
        build_graphviz_model
        parse_plain_graphviz(g.output(plain: String))
      end

      private

      def scalef(v)
        v.to_f * SCALE_FACTOR
      end

      def scalefy(y)
        @height - scalef(y)
      end

      # graph scale width height
      def plain_graph(cols)
        @scale, @width, @height = cols.map(&:to_f)
        @width = scalef(@width)
        @height = scalef(@height)
        nil
      end

      # node name x y width height label style shape color fillcolor
      def plain_gv_node(cols)
        id, x, y, width, height = cols
        GVNode.new(element_by_id(id), scalef(x), scalefy(y), scalef(width), scalef(height))
      end

      def plain_gv_edge(cols)
        # edge tail head n x1 y1 .. xn yn [label xl yl] style color
        target_id, source_id, point_count = cols
        point_count = point_count.to_i
        points = cols.slice(3, 2 * point_count)
        id = cols[3 + (2 * point_count)]
        GVEdge.new(
          relationship_by_id(id),
          element_by_id(source_id),
          element_by_id(target_id),
          make_bendpoints(points.map(&:to_f))
        )
      end

      # The points we get from graphviz are a set of bspline control points
      # So theory: we could take 1st point and every 3rd pt after
      def make_bendpoints(points)
        all_points = []
        points.each_slice(2) { |xy| all_points << xy }
        bps = []
        all_points.each_slice(3) { |ctrl| bps << ctrl[0] }
        bps.reverse.map do |xy|
          DataModel::Location.new(
            x: scalef(xy[0]) + 55,
            y: scalefy(xy[1]) + 37.5
          )
        end
      end

      def parse_plain_line(line)
        cols = line.split
        case cols.shift
        when "graph"
          plain_graph(cols)
        when "node"
          plain_gv_node(cols)
        when "edge"
          plain_gv_edge(cols)
        end
      end

      def parse_plain_graphviz(str)
        str.each_line.map { |line| parse_plain_line(line) }.compact
      end

      def build_graphviz_model
        @g = GraphViz.new( :G, :type => :digraph )
        g.node["fixedsize"] = "true"
        g.node["width"] = 1.0
        g.node["height"] = 0.5
        g.node["shape"] = "box"
        g.edge["dir"] = "none"
        g.edge["headclip"] = "false"
        g.edge["tailclip"] = "false"
        g["splines"] = "ortho"
        g["rankdir"] = "TB"
        g["dpi"] = 110.0

        elements = @relationships.map { |rel| [rel.source, rel.target] }.flatten.uniq

        node_map = elements.each_with_object({}) do |el, hash|
          hash[el] = g.add_nodes(el.id, id: el.id, label: el.name)
        end

        @relationships.each do |rel|
          g.add_edges(node_map[rel.target], node_map[rel.source], label: rel.id)
        end
      end

      def element_by_id(id)
        id = id.tr('"', '')
        @elements.find { |el| el.id == id }
      end

      def relationship_by_id(id)
        id = id.tr('"', '')
        @relationships.find { |rel| rel.id == id }
      end
    end
  end
end
