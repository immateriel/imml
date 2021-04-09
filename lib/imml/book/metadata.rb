require 'imml/book/primitives'
module IMML
  module Book
    class ContributorRole < Entity
      attr_accessor :role

      def parse(node)
        super
        @role = Text.new(node.text)
      end

      def write(xml)
        super
        attrs = self.attributes
        xml.role(attrs, @role)
      end
    end

    class Contributor < EntityWithUid
      attr_accessor :name, :role, :uid

      def initialize
        super
        @role = ContributorRole.new
      end

      def self.create(name, role = nil, uid = nil)
        contributor = Contributor.new
        contributor.name = name
        contributor_role = ContributorRole.new
        if role
          contributor_role.role = role
        else
          contributor_role.unsupported = true
        end
        contributor.role = contributor_role
        if uid
          contributor.uid = uid
        end
        contributor
      end

      def parse(node)
        super
        @uid = node["uid"]
        node.children.each do |child|
          case child.name
          when "role"
            @role.parse(child)
          when "name"
            @name = Text.new(child.text)
          else
            # unknown
          end
        end
      end

      def write(xml)
        super
        xml.contributor(self.attributes) {
          if @name
            @role.write(xml)
            xml.name(@name)
          end
        }
      end
    end

    class Contributors < EntityCollection
      def parse(node)
        super
        node.children.each do |child|
          if child.element?
            contributor = Contributor.new
            contributor.parse(child)
            self << contributor
          end
        end
      end

      def self.create
        contributors = Contributors.new
        contributors
      end

      def write(xml)
        super
        xml.contributors(self.attributes) {
          self.each do |contributor|
            contributor.write(xml)
          end
        }
      end
    end

    class Collection < EntityWithUid
      attr_accessor :name, :uid

      def parse(node)
        super
        @name = Text.new(node.text)
        @uid = node["uid"]
      end

      def self.create(name, uid = nil)
        collection = Collection.new
        collection.name = name
        if uid
          collection.uid = uid
        end
        collection
      end

      def write(xml)
        super
        if @name
          attrs = self.attributes
          xml.collection(attrs, @name)
        end
      end

      def to_s
        self.name
      end
    end

    class Topic < Entity
      attr_accessor :type, :identifier

      def parse(node)
        super
        @type = node["type"]
        @identifier = Text.new(node.text)
      end

      def self.create(type, identifier)
        topic = Topic.new
        topic.type = type
        topic.identifier = Text.new(identifier)
        topic
      end

      def write(xml)
        super
        attrs = self.attributes
        if @type
          attrs[:type] = @type
        end
        xml.topic(attrs, @identifier)
      end
    end

    class Topics < EntityCollection
      def parse(node)
        super
        node.children.each do |child|
          if child.element?
            topic = Topic.new
            topic.parse(child)
            self << topic
          end
        end
      end

      def self.create
        topics = Topics.new
        topics
      end

      def write(xml)
        super
        xml.topics(self.attributes) {
          self.each do |topic|
            topic.write(xml)
          end
        }
      end
    end

    class Publisher < EntityWithUid
      attr_accessor :name, :uid

      def parse(node)
        super
        @uid = node["uid"]
        @name = Text.new(node.text)
      end

      def self.create(name, uid = nil)
        publisher = Publisher.new
        publisher.name = Text.new(name)
        if uid
          publisher.uid = uid
        end
        publisher
      end

      def write(xml)
        super
        if @name
          attrs = self.attributes
          xml.publisher(attrs, @name)
        end
      end
    end

    class Imprint < EntityWithUid
      attr_accessor :name, :uid

      def parse(node)
        super
        @uid = node["uid"]
        @name = Text.new(node.text)
      end

      def self.create(name, uid = nil)
        imprint = Imprint.new
        imprint.name = Text.new(name)
        if uid
          imprint.uid = uid
        end
        imprint
      end

      def write(xml)
        super
        if @name
          attrs = self.attributes
          xml.publisher(attrs, @name)
        end
      end
    end

    class Metadata < IMML::Object
      attr_accessor :title, :subtitle, :contributors, :topics, :collection, :language, :publication, :publisher, :description
      attr_accessor :edition # 201
      attr_accessor :imprint # 202

      def initialize
        @collection = nil
        @publisher = nil

        @contributors = Contributors.new
      end

      def attach_version v
        @contributors.version = v
      end

      def self.create(title, language, description, subtitle = nil, publication = nil)
        metadata = Metadata.new
        metadata.title = Text.new(title)
        metadata.language = Text.new(language)
        metadata.description = Text.new(description)
        metadata.publication = publication
        if subtitle and subtitle != ""
          metadata.subtitle = Text.new(subtitle)
        end
        metadata
      end

      def parse(node)
        node.children.each do |child|
          case child.name
          when "title"
            @title = Text.new(child.text)
            @title.parse(child)
          when "subtitle"
            @subtitle = Text.new(child.text)
            @subtitle.parse(child)
          when "edition"
            @edition = child.text.to_i
          when "description"
            if child["format"] == "xhtml"
              @description = Text.new(child.to_xml)
            else
              @description = Text.new(child.text)
            end
            @description.parse(child)
          when "collection"
            @collection = Collection.new
            @collection.parse(child)
          when "language"
            @language = Text.new(child.text)
            @language.parse(child)
          when "publication"
            @publication = Date.strptime(child.text, "%Y-%m-%d")
          when "publisher"
            @publisher = Publisher.new
            @publisher.parse(child)
          when "imprint"
            @imprint = Imprint.new
            @imprint.parse(child)
          when "topics"
            self.topics = Topics.new
            self.topics.parse(child)
          when "contributors"
            self.contributors.parse(child)
          else
            # unknown
          end
        end
      end

      def write(xml)
        xml.metadata {
          self.title.write_tag(xml, "title")

          if self.subtitle
            self.subtitle.write_tag(xml, "subtitle")
          end

          if self.contributors
            self.contributors.write(xml)
          end

          if self.language
            self.language.write_tag(xml, "language")
          end

          if self.collection
            self.collection.write(xml)
          end

          if self.version.to_i > 200
            if self.edition
              xml.edition(self.edition)
            end
          end

          if self.topics
            self.topics.write(xml)
          end

          if self.version.to_i > 201
            if self.imprint
              self.imprint.write(xml)
            end
          end

          if self.publisher
            self.publisher.write(xml)
          end

          if self.publication
            xml.publication(self.publication.strftime("%Y-%m-%d"))
          end

          if self.description
            self.description.write_tag(xml, "description")
          end
        }
      end
    end
  end
end
