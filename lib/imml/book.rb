require 'date'
require 'digest'
require 'shellwords'

require 'imml/book/metadata'
require 'imml/book/assets'
require 'imml/book/offer'

module IMML
  module Book
    class Book < IMML::Object
      attr_accessor :ean, :uid, :url
      attr_accessor_with_version :metadata, :assets, :offers

      def initialize
        super
        @offers = []
      end

      def offer
        @offers.first
      end

      def offer= v
        if self.offers.count > 0
          @offers[0] = v
        else
          @offers << v
        end
      end

      def self.create(ean)
        book = Book.new
        book.ean = ean
        book
      end

      def parse(node)
        @ean = node["ean"]
        @uid = node.attributes["uid"].value if node.attributes["uid"]
        @url = node.attributes["url"].value if node.attributes["url"]
        node.children.each do |child|
          case child.name
            when "metadata"
              self.metadata = Metadata.new
              self.metadata.parse(child)
            when "assets"
              self.assets = Assets.new
              self.assets.parse(child)
            when "offer"
              o = Offer.new
              o.parse(child)
              self.offers << o
            when "offers"
              child.children.each do |subchild|
                case subchild.name
                  when "offer"
                    o = Offer.new
                    o.parse(subchild)
                    self.offers << o
                  else
                    # unknown
                end
              end
            else
              # unknown
          end
        end
      end

      def write(xml)
        attrs = {"ean"=>@ean}
        attrs["uid"] = @uid if @uid
        attrs["sc:url"] = @url if @url
        xml.book(attrs) {
          if self.metadata
            self.metadata.write(xml)
          end
          if self.assets
            self.assets.write(xml)
          end
          if self.version.to_i > 201
            if self.offers.count > 0
              if self.offers.count > 1
                self.offers.each do |o|
                  o.write(xml)
                end
              else
                self.offer.write(xml)
              end
            end
          else
            self.offer.write(xml)
          end
        }
      end
    end
  end
end
