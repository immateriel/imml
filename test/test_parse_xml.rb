# coding: utf-8
require 'helper'

class TestParseXml < Minitest::Test
  context "le faiseur d'anges" do
    setup do
      @doc = IMML::Document.new
      @valid = @doc.parse_file("test/fixtures/9781909782471.xml",true)
      @book=@doc.book
      @metadata=@book.metadata
      @offer=@book.offer
    end

    should "be valid" do
      assert_equal true, @valid
    end

    should "have title" do
      assert_equal "Le faiseur d'anges", @metadata.title
    end
    should "have publisher name" do
      assert_equal "Les Editions De Londres", @metadata.publisher.name
    end

    should "be published" do
      assert_equal Date.new(2013,2,12), @metadata.publication
    end

    should "be in french" do
      assert_equal "fre", @metadata.language
    end

#    should "be bundle" do
#      assert_equal "bundle", @offer.format
#    end

  end

  # test store check
  context "Moi Bobby bébé zombie" do
    setup do
      @doc = IMML::Document.new
      @valid = @doc.parse_file("test/fixtures/9782363761514.xml",true)
      @book=@doc.book
      @metadata=@book.metadata
      @offer=@book.offer
    end

    should "be valid" do
      assert_equal true, @valid
    end

    should "have title score" do
      assert_equal 0.9, @metadata.title.score
    end

  end

end
