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
      @doc.book.metadata.topics=IMML::Book::Topics.create
      @doc.book.metadata.topics << IMML::Book::Topic.create("bisac","FIC027120")

      @doc.book.assets=IMML::Book::Assets.create
      @doc.book.assets.cover=IMML::Book::Cover.create("image/png",1000)
      @doc.book.offer=IMML::Book::Offer.create("digital",true)
      @doc.book.offer.prices << IMML::Book::Price.create("EUR",6.49,"WORLD")
      @doc.book.offer.sales_start_at=IMML::Book::SalesStartAt.create_unsupported
      puts @doc.to_xml

    end


    should "be valid" do
      testdoc = IMML::Document.new
      res=testdoc.parse_data(@doc.to_xml)
      assert_equal true,res
    end


  end

  context "write reporting" do
    setup do
      puts "WRITE REPORTING"

      @doc = IMML::Document.new
      @doc.reporting = IMML::Reporting::Reporting.create(Date.today)
      @doc.reporting.lines << IMML::Reporting::Line.create("9781909782471","purchase","individual",5.5,1.87,1.99,1,"EUR","FR")
      puts @doc.to_xml

    end

    should "be valid" do
      testdoc = IMML::Document.new
      res=testdoc.parse_data(@doc.to_xml)
      assert_equal true,res
    end

  end
end