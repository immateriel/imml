require 'posix/spawn'
require 'rnv'

module IMML
  class Validator
    def self.validate(xml)
    end

    def self.errors(out)
    end

    def self.scheme_dir
      File.dirname(__FILE__) + "/../../data"
    end
  end

  class ValidationError
    attr_accessor :line, :column, :message, :details

    def initialize(line, column, message)
      @line = line
      @column = column
      @message = message
      @details = {}
    end

    def to_s
      out = ""
        out << "#{@line}:#{@column} #{@message}\n"
        @details.each do |k,lines|
          out << "#{k}:\n"
          lines.each do |line|
            out << "\t#{line}\n"
          end
        end
      out
    end

    def dump
      puts self.to_s
    end
  end

  # does not work
  class NokogiriValidator < Validator
    def self.validate(xml)
      schema = Nokogiri::XML::RelaxNG(File.open("#{self.scheme_dir}/imml.rng"))
      schema.validate(xml).map {|e| ValidationError.new(e.line, e.column, e.message)}
    end
  end

  class RnvValidator < Validator
    def self.validate(xml)
      validator = RNV::Validator.new
      validator.load_schema_from_file("#{self.scheme_dir}/imml.rnc")
      validator.parse_string(xml.to_xml)
      validator.errors.map do |err|
        ValidationError.new(err.line, err.col, err.message+"\n"+err.expected)
      end
    end
  end
end