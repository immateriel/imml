module IMML

  module Book

    class Entity
      attr_accessor :unsupported

      def parse(node)
        if node["unsupported"]
          @unsupported=true
        end
      end

      def attributes
        attrs={}
        if @unsupported
          attrs[:unsupported]=@unsupported
        end
        attrs
      end
    end

    class EntityWithUid < Entity
      attr_accessor :uid

      def attributes
        attrs=super
        if @uid
          attrs[:uid]=@uid
        end
        attrs
      end
    end

    class ContributorRole < Entity
      attr_accessor :role
      def parse(node)
        super
        @role=node.text
      end

      def write(xml)
        xml.role(@role)
      end
    end

    class Contributor < EntityWithUid
      attr_accessor :name, :role, :uid

      def initialize
        @role=ContributorRole.new
      end

      def self.create(name,role=nil,uid=nil)
        contributor=Contributor.new
        contributor.name=name
        contributor_role=ContributorRole.new
        if role
          contributor_role.role=role
        else
          contributor_role.unsupported=true
        end

        contributor.role=contributor_role
        if uid
          contributor.uid=uid
        end
        contributor
      end

      def parse(node)
        super
        @uid=node["uid"]
        node.children.each do |child|
          case child.name
            when "role"
              @role.parse(child)
            when "name"
              @name=child.text
          end
        end
      end

      def write(xml)
        xml.contributor(self.attributes) {
          @role.write(xml)
          xml.name(@name)
        }
      end
    end

    class Collection < EntityWithUid
      attr_accessor :name, :uid

      def parse(node)
        super
        @name=node.text
        @uid=node["uid"]
      end

      def write(xml)
        if @name
          attrs=self.attributes
          xml.collection(attrs, @name)
        end
      end
    end

    class Topic < Entity
      attr_accessor :type, :identifier

      def parse(node)
        super
        @type=node["type"]
        @identifier=node.text
      end

      def write(xml)
        if @identifier
          attrs={}
          if @type
            attrs[:type]=@type
          end
          xml.topic(attrs, @identifier)
        end
      end
    end

    class Publisher < EntityWithUid
      attr_accessor :name, :uid

      def parse(node)
        super
        @uid=node["uid"]
        @name=node.text
      end

      def write(xml)
        if @name
        attrs=self.attributes
        xml.publisher(attrs, @name)
        end
      end

    end

    class Metadata

      attr_accessor :title, :subtitle, :contributors, :topics, :collection, :language, :publisher, :description

      def initialize
        @collection=nil
        @publisher=nil

        @contributors=[]
        @topics=[]
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "title"
              @title=child.text
            when "subtitle"
              @subtitle=child.text
            when "description"
              @description=child.text
            when "collection"
              @collection=Collection.new
              @collection.parse(child)
            when "language"
              @language=child.text
            when "publisher"
              @publisher=Publisher.new
              @publisher.parse(child)
            when "topics"
              child.children.each do |topic_node|
                if topic_node.element?
                topic=Topic.new
                topic.parse(topic_node)
                @topics << topic
                end
              end
            when "contributors"
              child.children.each do |contributor_node|
                if contributor_node.element?
                contributor=Contributor.new
                contributor.parse(contributor_node)
                @contributors << contributor
                end
              end
          end
        end
      end

      def write(xml)
        xml.metadata {
          xml.title(self.title)
          if self.subtitle
            xml.subtitle(self.subtitle)
          end
          xml.contributors {
            self.contributors.each do |c|
              c.write(xml)
            end
          }

          if self.collection
            self.collection.write(xml)
          end

          xml.topics {
            @topics.each do |topic|
              topic.write(xml)
            end
          }

          if self.publisher
            self.publisher.write(xml)
          end

          if @description
            xml.description(@description)
          end

        }
      end
    end

    class Asset < Entity
      attr_accessor :mimetype, :url
      def parse(node)
        super
        @mimetype=node["mimetype"]
        @url=node["url"]
      end

      def attrs
        attrs=self.attributes
        if @mimetype
          attrs[:mimetype]=@mimetype
        end
        if @url
          attrs[:url]=@url
        end
        attrs
      end

    end

    class Cover < Asset
      def write(xml)
        xml.cover(self.attrs)
      end

    end

    class Extract < Asset
      def write(xml)
        xml.extract(self.attrs)
      end

    end

    class Full < Asset
      def write(xml)
        xml.full(self.attrs)
      end

    end

    class Assets
      attr_accessor :cover, :extracts, :fulls

      def initialize
        @extracts=[]
        @fulls=[]
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "cover"
              @cover=Cover.new
              @cover.parse(child)
            when "extract"
              extract=Extract.new
              extract.parse(child)
              @extracts << extract
            when "full"
              full=Full.new
              full.parse(child)
              @fulls << full
          end
        end
      end

      def write(xml)
        xml.assets {
        if @cover
          @cover.write(xml)
        end

        @extracts.each do |e|
          e.write(xml)
        end

        @fulls.each do |f|
          f.write(xml)
        end
        }
      end

    end

    class Price < Entity
      attr_accessor :currency, :current_amount, :territories
      def parse(node)
        super
        @currency=node["currency"]
        node.children.each do |child|
          case child.name
            when "current_amount"
              @current_amount=child.text.to_i
            when "territories"
              @territories=child.text
          end
        end
      end
      def write(xml)
        xml.price(:currency=>@currency) {
          xml.current_amount(@current_amount)
          xml.territories(@territories)
        }
      end
    end

    class Offer
      attr_accessor :support, :ready_for_sale, :sales_start_at, :prices

      def initialize
        @prices=[]
      end
      def parse(node)

        node.children.each do |child|
          case child.name
            when "support"
              @support=child.text
            when "ready_for_sale"
              @ready_for_sale=(child.text == "true")
            when "sales_start_at"
              if child.text!=""
                @sales_start_at=Date.strptime(child.text,"%Y-%m-%d")
              end
            when "prices"
              child.children.each do |price_node|
                if price_node.element?
                  price=Price.new
                  price.parse(price_node)
                  @prices << price
                end
              end

          end
        end
      end

      def write(xml)
        xml.offer {
        if @support
          xml.support(@support)
        end
        if @ready_for_sale
          xml.ready_for_sale(@ready_for_sale)
        end
        if @sales_start_at
          xml.sales_start_at(@sales_start_at)
        end
        xml.prices {
        @prices.each do |price|
          price.write(xml)
        end
        }

        }
      end
    end

    class Book
      attr_accessor :ean, :metadata, :assets, :offer

      def initialize
        @metadata=Metadata.new
        @assets=Assets.new
        @offer=Offer.new
      end

      def parse(node)
        @ean=node["ean"]
        node.children.each do |child|
          case child.name
            when "metadata"
              @metadata.parse(child)
            when "assets"
              @assets.parse(child)
            when "offer"
              @offer.parse(child)
          end
        end
      end

      def write(xml)
        xml.book(:ean=>@ean) {
          @metadata.write(xml)
          @assets.write(xml)
          @offer.write(xml)
        }
      end

    end

  end


end