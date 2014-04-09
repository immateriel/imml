module IMML
  module Reporting

    class ExtraParam
      attr_accessor :key, :value

      def self.create(key,value)
        extra=ExtraParam.new
        extra.key=key
        extra.value=value
        extra
      end

      def parse(node)
        @key=node["key"]
        @value=node["value"]
      end

      def write(xml)
        xml.extra_param(:key=>self.key, :value=>self.value)
      end
    end

    class Line
      attr_accessor :ean, :type, :customer, :tax, :net_amount, :unit_price, :quantity, :currency, :country, :extra_params

      def initialize
        @extra_params=[]
      end

      def self.create(ean,type,customer,tax,net_amount,unit_price,quantity,currency,country)
        line=Line.new
        line.ean=ean
        line.type=type
        line.customer=customer
        line.tax=tax
        line.net_amount=net_amount
        line.unit_price=unit_price
        line.quantity=quantity
        line.currency=currency
        line.country=country
        line
      end

      def parse(node)
        @ean=node["ean"]
        @type=node["type"]
        @customer=node["customer"]
        @tax=node["tax"].to_f
        @net_amount=node["net_amount"].to_f
        @unit_price=node["unit_price"].to_f
        @quantity=node["quantity"].to_i
        @currency=node["currency"]
        @country=node["country"]
      end

      def write(xml)
        xml.line(:ean=>self.ean,:type=>self.type,:customer=>self.customer,
                  :tax=>self.tax, :net_amount=>self.net_amount, :unit_price=>self.unit_price,
                  :quantity=>self.quantity, :currency=>self.currency, :country=>self.country) {
          @extra_params.each do |extra|
            extra.write(xml)
          end
        }
      end
    end

    class Reporting
      attr_accessor :date, :lines

      def initialize
        @lines=[]
      end

      def self.create(date)
        reporting=Reporting.new
        reporting.date=date
        reporting
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "lines"
              child.children.each do |line_child|
                if line_child.element?
                  line=Line.new
                  line.parse(line_child)
                  @lines << line
                end
              end
          end
        end
      end

      def write(xml)
        xml.reporting(:date=>@date) {
          xml.lines {
            @lines.each do |line|
              line.write(xml)
            end
          }
        }
      end

    end
  end
end