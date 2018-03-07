# automaticaly set version to children nodes
class Class
  def attr_accessor_with_version(*attrs_name)
    attrs_name.map! { |attr| attr.to_s }

    attrs_name.each do |attr_name|
      #getter
      self.class_eval("def #{attr_name};@#{attr_name};end")

      #setter
      self.class_eval %Q{
      def #{attr_name}=(val)
        @#{attr_name}=val
        if @#{attr_name}.respond_to?(:version)
          @#{attr_name}.version=self.version
          if @#{attr_name}.respond_to?(:attach_version)
            @#{attr_name}.attach_version self.version
          end
        else
          puts "WARN: #{attr_name} do not have version attribute"
        end
      end
    }
    end
  end
end

module IMML
  class Object
    attr_accessor :version

    def attach_version v
    end
  end
end

require 'nokogiri'
require 'levenshtein-ffi'
require 'open3'
require 'imml/header'
require 'imml/book'
require 'imml/reporting'
require 'imml/validator'

module IMML

  def self.current_version
    "2.0.2"
  end

  class Version
    attr_accessor :major, :minor, :fixes

    def initialize(version)
      version.gsub(/(\d+)\.(\d+)\.?(\d*)/) do
        @major=$1.to_i
        @minor=$2.to_i
        @fixes=$3.to_i
      end
    end

    def to_s
      vstr="#{@major}.#{@minor}"
      if @fixes > 0
        vstr+=".#{@fixes}"
      end
      vstr
    end

    def to_i
      100*@major+10*@minor+@fixes
    end
  end

  class Document < IMML::Object
    attr_accessor :errors
    attr_accessor_with_version :header, :book, :reporting, :extensions

    def validator
      RnvValidator
    end

    def initialize(version=IMML.current_version, extensions = [])
      @version = Version.new(version)
      @extensions = extensions
    end

    def parse(xml, valid=true)
      @errors=[]
      if valid
        @errors=self.validate(xml)
      end
      if @errors.length==0
        @version=Version.new(xml.root["version"])
        xml.children.each do |root|
          case root.name
            when "imml"
              @version=root["version"].to_s
              root.children.each do |child|
                case child.name
                  when "header"
                    self.header=Header::Header.new
                    self.header.parse(child)
                  when "book"
                    self.book=Book::Book.new
                    self.book.parse(child)
                  when "reporting"
                    self.reporting=Reporting::Reporting.new
                    self.reporting.parse(child)
                  else
                    # unknown
                end
              end
          end
        end
        true
      else
        self.dump_errors(errors)
        false
      end
    end

    def validate(xml)
      validator.validate(xml)
    end

    # DEPRECATED
    def dump_errors(errors)
      if @errors.length > 0
        puts "IMML is invalid: "

        @errors.each do |error|
          error.dump
        end
      end
    end

    def parse_data(data, valid=true)
      xml=Nokogiri::XML.parse(data)
      self.parse(xml, valid)
    end

    def parse_file(file, valid=true)
      self.parse_data(File.open(file).read, valid)
    end

    def write(xml)
      attrs={:version => @version.to_s}
      if @version.to_i > 201
        attrs[:xmlns] = "http://ns.immateriel.fr/imml"
      end
      @extensions.each do |ext|
        case ext
          when :store_check
            attrs["xmlns:sc"] = "http://ns.immateriel.fr/imml/store_check"
          else
            # unknown extension
        end
      end
      xml.imml(attrs) {
        if self.header
          self.header.write(xml)
        end
        if self.book
          self.book.write(xml)
        end
        if self.reporting
          self.reporting.write(xml)
        end
      }
    end

    def xml_builder
      Nokogiri::XML::Builder.new do |xml|
        self.write(xml)
      end
    end

    def to_xml
      self.xml_builder.to_xml
    end
  end
end