
module IMML
end

require 'nokogiri'
require 'imml/header'
require 'imml/book'
require 'imml/order'

module IMML
  class Document
    attr_accessor :version,:header, :book, :order

    def parse(xml)
      root=xml.at("//imml")
      @version=root["version"].to_f
      root.children.each do |child|
        case child.name
          when "header"
          when "book"
            @book=Book::Book.new
            @book.parse(child)
          when "order"

        end
      end
    end

    def parse_data(data)
      xml=Nokogiri::XML.parse(data)
      self.parse(xml)
    end

    def parse_file(file)
      self.parse_data(File.open(file).read)
    end
  end



end