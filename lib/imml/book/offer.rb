require 'imml/book/primitives'
module IMML
  module Book
    class Interval < Entity
      attr_accessor :start_at, :end_at, :amount

      def self.create(amount, start_at = nil, end_at = nil)
        interval = Interval.new
        interval.amount = amount
        interval.start_at = start_at
        interval.end_at = end_at
        interval
      end

      def parse(node)
        @amount = node.text.to_f
        if node["start_at"]
          @start_at = Date.strptime(node["start_at"], "%Y-%m-%d")
        end
        if node["end_at"]
          @end_at = Date.strptime(node["end_at"], "%Y-%m-%d")
        end
      end

      def write(xml)
        super
        attrs = self.attributes
        if @start_at
          attrs[:start_at] = @start_at
        end
        if @end_at
          attrs[:end_at] = @end_at
        end
        xml.interval(attrs, @amount)
      end
    end

    class Price < Entity
      attr_accessor :currency, :current_amount, :territories, :intervals

      def initialize
        @intervals = []
      end

      def self.create(currency, amount, territories)
        price = Price.new
        price.currency = currency
        price.current_amount = amount
        price.territories = territories
        price
      end

      def parse(node)
        super
        @currency = node["currency"]
        node.children.each do |child|
          case child.name
            when "current_amount"
              # Float or Integer ?
              @current_amount = child.text.to_f
            when "territories"
              @territories = Text.new(child.text)
            when "intervals"
              child.children.each do |interval_node|
                if interval_node.element?
                  interval = Interval.new
                  interval.parse(interval_node)
                  @intervals << interval
                end
              end
            else
              # unknown
          end
        end
      end

      def write(xml)
        super
        xml.price(:currency => @currency) {
          xml.current_amount(self.current_amount)
          xml.territories(self.territories)
          if @intervals.length > 0
            xml.intervals {
              @intervals.each do |interval|
                interval.write(xml)
              end
            }
          end
        }
      end
    end

    class Prices < EntityCollection
      def parse(node)
        super
        node.children.each do |child|
          if child.element?
            price = Price.new
            price.parse(child)
            self << price
          end
        end
      end

      def self.create
        prices = Prices.new
        prices
      end

      def write(xml)
        super
        if self.length > 0
          xml.prices(self.attributes) {
            self.each do |price|
              price.write(xml)
            end
          }
        end
      end
    end

    class SalesStartAt < Entity
      attr_accessor :date

      def self.create(date)
        sales_start_at = SalesStartAt.new
        sales_start_at.date = date
        sales_start_at
      end

      def parse(node)
        super
        if node.text and node.text != ""
          @date = Date.strptime(node.text, "%Y-%m-%d")
        end
      end

      def write(xml)
        super
        xml.sales_start_at(self.attributes, @date)
      end
    end

    class SalesModel < Entity
      attr_accessor :type, :available, :customer, :format, :protection

      def self.create(type, available, customer, format, protection)
        model = SalesModel.new
        model.type = type
        model.available = available
        model.customer = customer
        model.format = format
        model.protection = protection
        model
      end

      def parse(node)
        @type = node["type"]
        @available = node["available"] == "true" ? true : false
        @customer = node["customer"]
        @format = node["format"]
        @protection = node["protection"]
      end

      def write(xml)
        xml.sales_model(:type => @type, :available => @available, :customer => @customer, :format => @format, :protection => @protection)
      end
    end

    class Alternative < Entity
      attr_accessor :ean, :medium

      def self.create(ean, medium)
        alternative = Alternative.new
        alternative.ean = ean
        alternative.medium = medium
        alternative
      end

      def parse(node)
        @ean = node["ean"]
        @medium = node["medium"]
      end

      def write(xml)
        xml.alternative(:ean => @ean, :medium => @medium)
      end
    end

    class Offer < Entity
      attr_accessor :medium, :pagination, :ready_for_sale, :sales_start_at, :prices, :prices_with_currency, :sales_models, :alternatives

      def self.create(medium, ready_for_sale)
        offer = Offer.new
        offer.medium = medium
        offer.ready_for_sale = ready_for_sale
        offer
      end

      def initialize
        @prices = Prices.new
        @prices_with_currency = {}
        @sales_models = []
        @alternatives = []
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "medium"
              @medium = child.text
            when "pagination"
              @pagination = child.text.to_i
            when "ready_for_sale"
              @ready_for_sale = (child.text == "true")
            when "sales_start_at"
              self.sales_start_at = SalesStartAt.new
              @sales_start_at.parse(child)
            when "prices"
              self.prices = Prices.new
              self.prices.parse(child)
              update_currency_hash
            when "sales_models"
              child.children.each do |model_node|
                if model_node.element?
                  model = SalesModel.new
                  model.parse(model_node)
                  @sales_models << model
                end
              end
            when "alternatives"
              child.children.each do |alt_node|
                if alt_node.element?
                  alt = Alternative.new
                  alt.parse(alt_node)
                  @alternatives << alt
                end
              end
            else
              # unknown
          end
        end
      end

      def write(xml)
        xml.offer {
          if self.medium
            xml.medium(self.medium)
          end
          if self.pagination
            xml.pagination(self.pagination)
          end
          unless self.ready_for_sale.nil?
            xml.ready_for_sale(self.ready_for_sale)
          end
          if self.sales_start_at
            self.sales_start_at.write(xml)
          end
          if self.prices
            self.prices.write(xml)
          end

          if alternatives.length > 0
            xml.alternatives {
              self.alternatives.each do |alt|
                alt.write(xml)
              end
            }
          end
          if sales_models.length > 0
            xml.sales_models {
              self.sales_models.each do |model|
                model.write(xml)
              end
            }
          end
        }
      end

      private
      def update_currency_hash
        @prices.each do |price|
          @prices_with_currency[price.currency] = price
        end
      end
    end
  end
end
