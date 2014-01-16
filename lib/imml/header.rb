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
      end
    end

    class Authentication
      attr_accessor :api_key

      def parse(node)
        @api_key=node[:api_key]
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
    end

    class Recipient < Reseller
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
    end

    class Reason
      attr_accessor :type

      def parse(node)
        @type=node[:type]
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

      end
    end
  end
end