
module IMML
end

require 'nokogiri'
require 'levenshtein'
require 'open3'
require 'imml/header'
require 'imml/book'
require 'imml/reporting'

module IMML
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
      out,status=Open3.capture2e("rnv #{self.scheme_dir}/imml.rnc", :stdin_data=>xml.to_xml)

      if out
        err=[]
        out.split(/\n/).each do |l|
          if l=~/.*\:\d+\:\d+\: error\:.*/
          line=l.gsub(/.*\:(\d+)\:(\d+)\: error\:(.*)/,'\1').strip
          col=l.gsub(/.*\:(\d+)\:(\d+)\: error\:(.*)/,'\2').strip
          msg=l.gsub(/.*\:(\d+)\:(\d+)\: error\:(.*)/,'\3').strip
          err << ValidationError.new(line,col,msg)
          else
            case l
              when /^required/,/^allowed/,/^\t/
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

  class Document
    attr_accessor :version, :header, :book, :reporting, :errors

    def validator
      RnvValidator
    end

    def initialize
      @version="2.0"
    end

    def parse(xml, valid=true)
      @errors=[]
      if valid
        @errors=self.validate(xml)
      end
      if @errors.length==0
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
      xml.imml(:version=>@version) {
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