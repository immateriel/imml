# coding: utf-8
require 'helper'

class TestWriteXml < Minitest::Test

  context "write book" do
    setup do
      @doc = IMML::Document.new
      @doc.book=IMML::Book::Book.create("9782365404785")
      @doc.book.metadata=IMML::Book::Metadata.create("Le souffle de l'ange","fre","Tome 1 : la mission","la mission",Date.new(2014,1,21))
      @doc.book.metadata.publisher=IMML::Book::Publisher.create("Éditions Sharon Kena")
      @doc.book.metadata.contributors << IMML::Book::Contributor.create("Sarah Slama","author")
      @doc.book.metadata.topics=IMML::Book::Topics.create
      @doc.book.metadata.topics << IMML::Book::Topic.create("bisac","FIC027120")

      @doc.book.metadata.edition = 1

      @doc.book.assets=IMML::Book::Assets.create
      @doc.book.assets.cover=IMML::Book::Cover.create("image/png",1000)
      @doc.book.assets.extracts << IMML::Book::Extract.create("application/epub+zip",1000)
      @doc.book.assets.fulls << IMML::Book::Full.create("application/epub+zip",1000,nil,nil,"http://localhost/full.epub","3210123456789")

      @doc.book.offer=IMML::Book::Offer.create("digital",true)
      @doc.book.offer.prices << IMML::Book::Price.create("EUR",6.49,"WORLD")
      @doc.book.offer.sales_start_at=IMML::Book::SalesStartAt.create(Date.new(2012,1,1))
    end

    should "be valid" do
      testdoc = IMML::Document.new
      res=testdoc.parse_data(@doc.to_xml)
      assert_equal true,res
    end
  end

  context "write reporting" do
    setup do
      @doc = IMML::Document.new
      @doc.reporting = IMML::Reporting::Reporting.create(Date.today)
      @doc.reporting.lines << IMML::Reporting::Line.create("9781909782471","purchase","individual",5.5,1.87,1.99,1,"EUR","FR")
    end

    should "be valid" do
      testdoc = IMML::Document.new
      res=testdoc.parse_data(@doc.to_xml)
      assert_equal true,res
    end
  end

  # test store check
  context "write store check book" do
    setup do
      @doc = IMML::Document.new("2.0.2",[:store_check])
      @doc.book=IMML::Book::Book.create("9782363761514")
      @doc.book.metadata=IMML::Book::Metadata.create("Moi Bobby bébé zombie","fre","Le petit boby")

      @doc.book.metadata.title.score = 0.9

      @doc.book.metadata.publisher=IMML::Book::Publisher.create("Walrus")
      @doc.book.metadata.contributors << IMML::Book::Contributor.create("Neil Jomunsi","author")
      @doc.book.metadata.topics=IMML::Book::Topics.create
      @doc.book.metadata.topics << IMML::Book::Topic.create_unsupported

      @doc.book.assets=IMML::Book::Assets.create
      @doc.book.assets.cover=IMML::Book::Cover.create("image/png",1000)
      @doc.book.assets.extracts << IMML::Book::Extract.create_unsupported
      @doc.book.assets.fulls << IMML::Book::Full.create_unsupported

      @doc.book.offer=IMML::Book::Offer.create("digital",true)
      @doc.book.offer.prices << IMML::Book::Price.create("EUR",2.49,"WORLD")
      @doc.book.offer.sales_start_at=IMML::Book::SalesStartAt.create_unsupported
    end

    should "be valid" do
      testdoc = IMML::Document.new
#      puts @doc.to_xml
      res=testdoc.parse_data(@doc.to_xml)
      assert_equal true,res
    end
  end
end