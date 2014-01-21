# coding: utf-8
require 'helper'

class TestWriteXml < Test::Unit::TestCase

  context "write book" do
    setup do
      puts "WRITE BOOK"
      @doc = IMML::Document.new
      @doc.book=IMML::Book::Book.create("9782365404785")
      @doc.book.metadata=IMML::Book::Metadata.create("Le souffle de l'ange","fre","Tome 1 : la mission","la mission",Date.new(2014,1,21))
      @doc.book.metadata.publisher=IMML::Book::Publisher.create("Éditions Sharon Kena")
      @doc.book.metadata.contributors << IMML::Book::Contributor.create("Sarah Slama","author")
      @doc.book.metadata.topics << IMML::Book::Topic.create("bisac","FIC027120")

      puts @doc.xml_builder.to_xml

    end


    should "fail" do
      assert_equal false, true
    end


  end
end