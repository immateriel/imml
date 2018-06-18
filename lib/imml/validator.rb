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
      @details = details
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
      schema.validate(xml).map {|e| ValidationError.new(e.line, e.column, e.message)}
    end
  end

  class RnvValidator < Validator
    def self.validate(xml)
      if system("which rnv > /dev/null")
        out, status = Open3.capture2e("rnv #{self.scheme_dir}/imml.rnc", :stdin_data => xml.to_xml)

        if out
          last_details = nil
          err = []
          out.split(/\n/).each do |l|
            if l =~ /.*\:\d+\:\d+\: error\:.*/
              l.gsub(/.*\:(\d+)\:(\d+)\: error\:(.*)/) do
                line = $1.strip
                col = $2.strip
                msg = $3.strip
                err << ValidationError.new(line, col, msg)
              end
            else
              case l
                when /^required/
                  last_details = :required
                when /^allowed/
                  last_details = :allowed
                when /^\t/
                  err.last.details ||= {}
                  err.last.details[last_details] ||= []
                  err.last.details[last_details] << l.gsub(/\t/,"")
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
end