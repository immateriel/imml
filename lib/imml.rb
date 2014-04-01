
module IMML
end

require 'nokogiri'
require 'levenshtein'
require 'imml/header'
require 'imml/book'
require 'imml/order'

module IMML
  class Document
    attr_accessor :version, :header, :book, :order

    def initialize
      @version="2.0"
    end

    def parse(xml, valid=true)
      errors=[]
      if valid
        errors=validate(xml)
      end
      if errors.length==0
        @version=xml.root["version"]
        xml.children.each do |root|
          case root.name
            when "imml"
              @version=root["version"].to_f
              root.children.each do |child|
                case child.name
                  when "header"
                    @header=Header::Header.new
                    @header.parse(child)
                  when "book"
                    @book=Book::Book.new
                    @book.parse(child)
                  when "order"
                end
              end
          end
        end
        true
      else
        puts "IMML is invalid: "
        errors.each do |error|
          puts " #{error.file}:#{error.line}:#{error.column}: error: #{error.message}"
        end
        false
      end
    end

    def validate(xml)
      schema = Nokogiri::XML::RelaxNG(File.open("data/imml.rng"))
      schema.validate(xml)
    end

    def parse_data(data, valid=true)
      xml=Nokogiri::XML.parse(data)
      self.parse(xml,valid)
    end

    def parse_file(file, valid=true)
      self.parse_data(File.open(file).read, valid)
    end

    def write(xml)
      xml.imml(:version=>@version) {
        if self.header
          self.header.write(xml)
        end
        if self.book
          self.book.write(xml)
        end
      }
    end

    def xml_builder
      builder = Nokogiri::XML::Builder.new do |xml|
        self.write(xml)
      end
      builder
    end

    def to_xml
      self.xml_builder.to_xml
    end

  end

end