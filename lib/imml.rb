
# automaticaly set version to children nodes
class Class
  def attr_accessor_with_version(*attrs_name)
    attrs_name.map!{|attr| attr.to_s}

    attrs_name.each do |attr_name|
      #getter
      self.class_eval("def #{attr_name};@#{attr_name};end")

      #setter
      self.class_eval %Q{
      def #{attr_name}=(val)
        @#{attr_name}=val
        if @#{attr_name}.respond_to?(:version)
          @#{attr_name}.version=self.version
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
  end
end

require 'nokogiri'
require 'levenshtein'
require 'open3'
require 'imml/header'
require 'imml/book'
require 'imml/reporting'

module IMML

  def self.current_version
    "2.0"
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

  class Validator
    def self.validate(xml)
    end
    def self.errors(out)
    end

    def self.scheme_dir
      File.dirname(__FILE__) + "/../data"
    end
  end

  class ValidationError
     attr_accessor :line, :column, :message
     def initialize(line,column,message)
       @line=line
       @column=column
       @message=message
     end
     def to_s
       "#{@line}:#{column}: error: #{message}"
     end
     def dump
       puts self.to_s
     end
  end

  # does not work
  class NokogiriValidator < Validator
    def self.validate(xml)
      schema = Nokogiri::XML::RelaxNG(File.open("#{self.scheme_dir}/imml.rng"))
      schema.validate(xml).map{|e| ValidationError.new(e.line,e.column,e.message)}
    end

  end

  class RnvValidator < Validator
    def self.validate(xml)
      if system("which rnv > /dev/null")
        out, status=Open3.capture2e("rnv #{self.scheme_dir}/imml.rnc", :stdin_data => xml.to_xml)

        if out
          err=[]
          out.split(/\n/).each do |l|
            if l=~/.*\:\d+\:\d+\: error\:.*/
              l.gsub(/.*\:(\d+)\:(\d+)\: error\:(.*)/) do
                line=$1.strip
                col=$2.strip
                msg=$3.strip
              end
              err << ValidationError.new(line, col, msg)
            else
              case l
                when /^required/, /^allowed/, /^\t/
                  err.last.message+="\n"+l
              end
            end
          end
          err
        else
          []
        end
      else
        raise "You must install rnv (http://www.davidashen.net/rnv.html) for XML validation"
      end
    end

  end

  class Document < IMML::Object
    attr_accessor :errors
    attr_accessor_with_version :header, :book, :reporting

    def validator
      RnvValidator
    end

    def initialize(version=IMML.current_version)
      @version=Version.new(version)
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
                    @header=Header::Header.new
                    @header.parse(child)
                  when "book"
                    @book=Book::Book.new
                    @book.parse(child)
                  when "reporting"
                    @reporting=Reporting::Reporting.new
                    @reporting.parse(child)
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
      self.parse(xml,valid)
    end

    def parse_file(file, valid=true)
      self.parse_data(File.open(file).read, valid)
    end

    def write(xml)
      xml.imml(:version=>@version.to_s) {
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