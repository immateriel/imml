# TODO
module IMML
  module Header

    class Param
      attr_accessor :name, :value

      def parse(node)
        @name=node[:name]
        @value=node[:value]
      end

      def write(xml)
        xml.param(:name => self.name, :value => self.value)
      end
    end

    class Authentication
      attr_accessor :api_key

      def parse(node)
        @api_key=node[:api_key]
      end

      def write(xml)
        xml.authentication(:api_key => self.api_key)
      end
    end

    class Reseller
      attr_accessor :reseller_id, :reseller_dilicom_gencod

      def parse(node)
        @reseller_id=node[:reseller_id]
        @reseller_dilicom_gencod=node[:reseller_dilicom_gencod]
      end

      def write(xml)
        xml.reseller(:reseller_id => self.reseller_id, :reseller_dilicom_gencod => self.reseller_dilicom_gencod)
      end

    end

    class Test
      attr_accessor :receive_url, :check_url, :sales_url

      def parse(node)
        node.children.each do |child|
          case child.name
            when "receive"
              @receive_url=node[:url]
            when "check"
              @check_url=node[:url]
            when "sales"
              @sales_url=node[:url]
          end
        end
      end

      def write(xml)
        xml.receive(:url => self.receive_url)
        xml.check(:url => self.check_url)
        xml.sales(:url => self.sales_url)

      end

    end

    class Header
      attr_accessor :params, :authentication, :reseller, :test, :reason

      def initialize

        @params=[]
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "params"
              child.children.each do |param_node|
                param=Param.new
                param.parse(param_node)
                @params << param
              end
            when "authentication"
              @authentication=Authentication.new
              @authentication.parse(child)
            when "reseller"
              @reseller=Reseller.new
              @reseller.parse(child)
            when "test"
              @test=Test.new
              @test.parse(child)
          end
        end
      end

      def write(xml)

        xml.header {
          unless @params.blank?
            xml.params {
              self.params.each do |param|
                param.write(xml)
              end
            }
          end
          if self.authentication
            self.authentication.write(xml)
          end
          if self.reseller
            self.reseller.write(xml)
          end
          if self.test
            self.test.write(xml)
          end
        }

      end
    end
  end
end