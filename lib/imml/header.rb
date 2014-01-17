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
        xml.param(:name => @name, :value => @value)
      end
    end

    class Authentication
      attr_accessor :api_key

      def parse(node)
        @api_key=node[:api_key]
      end

      def write(xml)
        xml.authentication(:api_key => @api_key)
      end
    end

    class Reseller
      attr_accessor :reseller_id, :reseller_dilicom_gencod

      def parse(node)
        @reseller_id=node[:reseller_id]
        @reseller_dilicom_gencod=node[:reseller_dilicom_gencod]
      end

    end

    class Emitter < Reseller

      def write(xml)
        xml.emitter(:reseller_id => @reseller_id, :reseller_dilicom_gencod => @reseller_dilicom_gencod)
      end
    end

    class Recipient < Reseller
      def write(xml)
        xml.recipient(:reseller_id => @reseller_id, :reseller_dilicom_gencod => @reseller_dilicom_gencod)
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
        xml.receive(:url => @receive_url)
        xml.check(:url => @check_url)
        xml.sales(:url => @sales_url)

      end

    end

    class Reason
      attr_accessor :type

      def parse(node)
        @type=node[:type]
      end

      def write(xml)
        xml.reason(:type => @type)
      end
    end

    class Header
      attr_accessor :params, :authentication, :emitter, :recipient, :test, :reason

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
            when "emitter"
              @emitter=Recipient.new
              @emitter.parse(child)
            when "recipient"
              @recipient=Recipient.new
              @recipient.parse(child)
            when "reason"
              @reason=Reason.new
              @reason.parse(child)
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
              @params.each do |param|
                param.write(xml)
              end
            }
          end
          if @authentication
            @authentication.write(xml)
          end
          if @emitter
            @emitter.write(xml)
          end
          if @recipient
            @recipient.write(xml)
          end
          if @reason
            @reason.write(xml)
          end
          if @test
            @test.write(xml)
          end
        }

      end
    end
  end
end