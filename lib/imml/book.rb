require 'date'
require 'digest'

module IMML

  module Book

    class Entity
      attr_accessor :attributes, :unsupported

      def initialize
        @attributes={}
      end

      def parse(node)
        if node["unsupported"]
          @unsupported=true
        end
      end

      def write(xml)
        if @unsupported
          @attributes[:unsupported]=@unsupported
        end
      end

      def supported?
        not @unsupported
      end

      def unsupported?
        @unsupported
      end

    end

    class EntityWithUid < Entity
      attr_accessor :uid

      def write(xml)
        super
        if @uid
          @attributes[:uid]=@uid
        end
      end
    end

    class Text < String
      def like?(t)
        dist=self.distance(t)
        if dist < ((self.length + t.length)/2.0) * 0.33
          true
        else
          false
        end
      end

      def distance(t)
        Levenshtein.distance(self.without_html.with_stripped_spaces.downcase, self.class.new(t).without_html.with_stripped_spaces.downcase)
      end

      def without_html
        Text.new(self.gsub(/&nbsp;/," ").gsub(/<[^>]*(>+|\s*\z)/m, ''))
      end

      def with_stripped_spaces
        Text.new(self.gsub(/\s+/," ").strip)
      end
    end

    class ContributorRole < Entity
      attr_accessor :role
      def parse(node)
        super
        @role=Text.new(node.text)
      end

      def write(xml)
        super
        xml.role(@role)
      end
    end

    class Contributor < EntityWithUid
      attr_accessor :name, :role, :uid

      def initialize
        super
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
              @name=Text.new(child.text)
          end
        end
      end

      def write(xml)
        super
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
        @name=Text.new(node.text)
        @uid=node["uid"]
      end

      def self.create(name,uid=nil)
        collection=Collection.new
        collection.name=name
        if uid
          collection.uid=uid
        end
        collection
      end

      def write(xml)
        super
        if @name
          attrs=self.attributes
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
        @type=node["type"]
        @identifier=Text.new(node.text)
      end

      def self.create(type,identifier)
        topic=Topic.new
        topic.type=type
        topic.identifier=Text.new(identifier)
        topic
      end

      def write(xml)
        super
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
        @name=Text.new(node.text)
      end

      def self.create(name, uid=nil)
        publisher=Publisher.new
        publisher.name=Text.new(name)
        if uid
          publisher.uid=uid
        end
        publisher
      end

      def write(xml)
        super
        if @name
        attrs=self.attributes
        xml.publisher(attrs, @name)
        end
      end

    end

    class Metadata

      attr_accessor :title, :subtitle, :contributors, :topics, :collection, :language, :publication, :publisher, :description

      def initialize
        @collection=nil
        @publisher=nil

        @contributors=[]
        @topics=[]
      end

      def self.create(title,language,description,subtitle=nil,publication=nil)
        metadata=Metadata.new
        metadata.title=Text.new(title)
        metadata.language=Text.new(language)
        metadata.description=Text.new(description)
        metadata.publication=publication
        if subtitle and subtitle!=""
          metadata.subtitle=Text.new(subtitle)
        end
        metadata
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "title"
              @title=Text.new(child.text)
            when "subtitle"
              @subtitle=Text.new(child.text)
            when "description"
              @description=Text.new(child.text)
            when "collection"
              @collection=Collection.new
              @collection.parse(child)
            when "language"
              @language=Text.new(child.text)
            when "publication"
              @publication=Date.strptime(child.text,"%Y-%m-%d")
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

          if self.language
            xml.language(self.language)
          end

          if self.collection
            self.collection.write(xml)
          end

          xml.topics {
            self.topics.each do |topic|
              topic.write(xml)
            end
          }

          if self.publisher
            self.publisher.write(xml)
          end

          if self.description
            xml.description(self.description)
          end

        }
      end
    end

    class Asset < Entity
      attr_accessor :mimetype, :url, :checksum
      def parse(node)
        super
        @mimetype=node["mimetype"]
        @url=node["url"]
      end

      def self.create(mimetype,url)
        asset=self.new
        asset.mimetype=mimetype
        asset.url=url
        asset
      end

      def write(xml)
        super
        if @mimetype
          @attributes[:mimetype]=@mimetype
        end
        if @url
          @attributes[:url]=@url
        end
      end

      def check_file(local_file)
        true
      end
    end

    class Cover < Asset
      def write(xml)
        super
        xml.cover(self.attributes)
      end

      # Wget needed - use curl instead ?
      def check_file(local_file)
        uniq_str=Digest::MD5.hexdigest("#{url}:#{local_file}")
        fn="/tmp/#{uniq_str}_"+File.basename(@url)
        system("wget -q #{@url} -O #{fn}")
        if File.exists?(fn)
          check_result=self.class.check_image(fn, local_file, uniq_str)
          FileUtils.rm_f(fn)
          if check_result*100 < 25
            true
          else
            false
          end
        else
          false
        end
      end

      private
      # ImageMagick needed
      def self.check_image(img1, img2, uniq_str, cleanup=true)
        tmp1="/tmp/check_image_#{Time.now.to_i}_#{uniq_str}_tmp1.png"
        # on supprime le transparent
        conv1=`convert #{img1} -trim +repage -resize 64 #{tmp1}`
        if File.exists?(tmp1)
          # on recupere la taille
          size1=`identify #{tmp1}`.chomp.gsub(/.*[^\d](\d+x\d+)[^\d].*/, '\1').split("x").map { |v| v.to_i }

          tmp2="/tmp/check_image_#{Time.now.to_i}_#{uniq_str}_tmp2.png"
          # on convertit l'image deux dans la taille de l'image un
          conv2=`convert #{img2} -trim +repage -resize #{size1.first}x#{size1.last}\\! #{tmp2}`

          if File.exists?(tmp2)
            tmp3="/tmp/check_image_#{Time.now.to_i}_#{uniq_str}_tmp3.png"
            # on compare
            result=`compare -dissimilarity-threshold 1 -metric mae #{tmp1} #{tmp2} #{tmp3} 2>/dev/stdout`.chomp
            if cleanup
              FileUtils.rm_f(tmp1)
              FileUtils.rm_f(tmp2)
              FileUtils.rm_f(tmp3)
            end
            result.gsub(/.*[^\(]\((.*)\).*/, '\1').to_f
          else
            1.0
          end
        else
          1.0
        end
      end
    end

    class ChecksumAsset < Asset
      def check_file(local_file)
        check_checksum(local_file)
      end

      # ZIP needed
      def calculate_checksum(local_file)
        case @mimetype
          when /epub/
            Digest::MD5.hexdigest(`unzip -p #{local_file}`)
          else
            Digest::MD5.hexdigest(File.read(local_file))
        end

      end

      def set_checksum(local_file)
        @checksum=self.calculate_checksum(local_file)
      end

      def check_checksum(local_file)
        @checksum == self.calculate_checksum(local_file)
      end
    end

    class Extract < ChecksumAsset
      def write(xml)
        super
        xml.extract(self.attributes)
      end

    end

    class Full < ChecksumAsset
      def write(xml)
        super
        xml.full(self.attributes)
      end
    end

    class Assets
      attr_accessor :cover, :extracts, :fulls

      def initialize
        @extracts=[]
        @fulls=[]
      end

      def self.create
        Assets.new
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
        if self.cover
          self.cover.write(xml)
        end

        self.extracts.each do |e|
          e.write(xml)
        end

        self.fulls.each do |f|
          f.write(xml)
        end
        }
      end

    end

    class Interval < Entity
      attr_accessor :start_at, :end_at, :amount

      def self.create(amount,start_at=nil,end_at=nil)
        interval=Interval.new
        interval.amount=amount
        interval.start_at=start_at
        interval.end_at=end_at
        interval
      end

      def parse(node)
        @amount=node.text.to_f
        if node["start_at"]
          @start_at=Date.strptime(node["start_at"],"%Y-%m-%d")
        end
        if node["end_at"]
          @end_at=Date.strptime(node["end_at"],"%Y-%m-%d")
        end
      end

      def write(xml)
        super
        attrs=self.attributes
        if @start_at
          attrs[:start_at]=@start_at
        end
        if @end_at
          attrs[:end_at]=@end_at
        end
        xml.interval(attrs,@amount)
      end


    end

    class Price < Entity
      attr_accessor :currency, :current_amount, :territories, :intervals

      def initialize
        @intervals=[]
      end

      def self.create(currency,amount,territories)
        price=Price.new
        price.currency=currency
        price.current_amount=amount
        price.territories=territories
        price
      end

      def parse(node)
        super
        @currency=node["currency"]
        node.children.each do |child|
          case child.name
            when "current_amount"
              # Float or Integer ?
              @current_amount=child.text.to_f
            when "territories"
              @territories=Text.new(child.text)
            when "intervals"
              child.children.each do |interval_node|
                interval=Interval.new
                interval.parse(interval_node)
                @intervals << interval
              end
          end
        end
      end
      def write(xml)
        super
        xml.price(:currency=>@currency) {
          xml.current_amount(self.current_amount)
          xml.territories(self.territories)
          if @intervals.length > 0
            xml.intervals
              @intervals.each do |interval|
                interval.write(xml)
              end
            end
        }
      end
    end

    class SalesStartAt < Entity
      attr_accessor :date

      def self.create(date)
        sales_start_at=SalesStartAt.new
        sales_start_at.date=date
        sales_start_at
      end

      def parse(node)
        super
        if node.text and node.text!=""
          @date=Date.strptime(node.text,"%Y-%m-%d")
        end
      end

      def write(xml)
        super
        xml.sales_start_at(self.attributes,@date)
      end
    end

    class Offer < Entity
      attr_accessor :medium, :format, :pagination, :ready_for_sale, :sales_start_at, :prices, :prices_with_currency, :protection

      def self.create(medium, format, protection, ready_for_sale)
        offer=Offer.new
        offer.medium=medium
        offer.format=format
        offer.protection=protection
        offer.ready_for_sale=ready_for_sale
        offer
      end

      def initialize
        @prices=[]
        @prices_with_currency={}
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "medium"
              @medium=child.text
            when "format"
              @format=child.text
            when "protection"
              @protection=child.text
            when "pagination"
              @pagination=child.text.to_i
            when "ready_for_sale"
              @ready_for_sale=(child.text == "true")
            when "sales_start_at"
              @sales_start_at=SalesStartAt.new
              @sales_start_at.parse(child)
            when "prices"
              child.children.each do |price_node|
                if price_node.element?
                  price=Price.new
                  price.parse(price_node)
                  @prices << price
                end
              end
              update_currency_hash
          end
        end

      end

      def write(xml)
        xml.offer {
        if self.medium
          xml.medium(self.medium)
        end
        if self.format
          xml.format(self.format)
        end
        if self.protection
          xml.protection(self.protection)
        end
        if self.pagination
          xml.pagination(self.pagination)
        end
        if self.ready_for_sale
          xml.ready_for_sale(self.ready_for_sale)
        end
        if self.sales_start_at
          self.sales_start_at.write(xml)
        end
        xml.prices {
          self.prices.each do |price|
          price.write(xml)
        end
        }

        }
      end

      private
      def update_currency_hash
        @prices.each do |price|
          @prices_with_currency[price.currency]=price
        end

      end
    end

    class Book
      attr_accessor :ean, :metadata, :assets, :offer

      def self.create(ean)
        book=Book.new
        book.ean=ean
        book
      end

      def parse(node)
        @ean=node["ean"]
        node.children.each do |child|
          case child.name
            when "metadata"
              @metadata=Metadata.new
              @metadata.parse(child)
            when "assets"
              @assets=Assets.new
              @assets.parse(child)
            when "offer"
              @offer=Offer.new
              @offer.parse(child)
          end
        end
      end

      def write(xml)
        xml.book(:ean => @ean) {
          if self.metadata
            self.metadata.write(xml)
          end
          if self.assets
            self.assets.write(xml)
          end
          if self.offer
            self.offer.write(xml)
          end
        }
      end

    end

  end


end