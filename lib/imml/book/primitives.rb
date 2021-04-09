module IMML
  module Book
    module UnsupportedMethods
      attr_accessor :attributes, :unsupported

      def parse_unsupported(node)
        if node["unsupported"]
          @unsupported = true
        end
      end

      def write_unsupported(xml)
        if @unsupported
          @attributes[:unsupported] = @unsupported
        end
      end

      def supported?
        not @unsupported
      end

      def unsupported?
        @unsupported
      end
    end

    module StoreCheckMethods
      attr_accessor :score

      def parse_score(node)
        if node.attributes["score"]
          @score = node.attributes["score"].value.to_f
        end
      end

      def write_score(xml)
        if @score
          @attributes["sc:score"] = @score
        end
      end
    end

    class Entity < IMML::Object
      include UnsupportedMethods
      include StoreCheckMethods

      def initialize
        @attributes = {}
      end

      def self.create_unsupported
        entity = self.new
        entity.unsupported = true
        entity
      end

      def parse(node)
        self.parse_unsupported(node)
        self.parse_score(node)
      end

      def write(xml)
        self.write_unsupported(xml)
        self.write_score(xml)
      end
    end

    class EntityCollection < Array
      include UnsupportedMethods
      include StoreCheckMethods

      attr_accessor :version

      def initialize
        @attributes = {}
      end

      def self.create_unsupported
        entity = self.new
        entity.unsupported = true
        entity
      end

      def parse(node)
        self.parse_unsupported(node)
        self.parse_score(node)
      end

      def write(xml)
        self.write_unsupported(xml)
        self.write_score(xml)
      end

      def << value
        if value.respond_to?(:version)
          value.version = self.version
        end
        super value
      end
    end

    class EntityWithUid < Entity
      attr_accessor :uid

      def write(xml)
        self.write_unsupported(xml)
        self.write_score(xml)
        if @uid
          @attributes[:uid] = @uid
        end
      end
    end

    class Text < String
      include UnsupportedMethods
      include StoreCheckMethods

      def initialize(str)
        super
        @attributes = {}
      end

      def like?(t)
        dist = self.distance(t)
        if dist < ((self.length + t.length) / 2.0) * 0.33
          true
        else
          false
        end
      end

      def parse(node)
        self.parse_unsupported(node)
        self.parse_score(node)
      end

      def write(xml)
        self.write_unsupported(xml)
        self.write_score(xml)
      end

      def write_tag(xml, tag)
        self.write(xml)
        xml.send(tag, self.attributes) {
          xml.text(self)
        }
      end

      def distance(t)
        Levenshtein.distance(self.without_html.with_stripped_spaces.downcase, self.class.new(t).without_html.with_stripped_spaces.downcase)
      end

      def without_html
        Text.new(self.gsub(/&nbsp;/, " ").gsub(/<[^>]*(>+|\s*\z)/m, ''))
      end

      def with_stripped_spaces
        Text.new(self.gsub(/\s+/, " ").strip)
      end
    end
  end
end
