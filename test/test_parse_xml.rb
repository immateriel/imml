# coding: utf-8
require 'helper'

class TestParseXml < Test::Unit::TestCase
  context "le faiseur d'anges" do
    setup do
      @doc = IMML::Document.new
      @doc.parse_file("test/fixtures/9781909782471.xml")
      @book=@doc.book
      @metadata=@book.metadata
      @offer=@book.offer
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
end
