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

    should "have nil title score" do
      assert_equal nil, @metadata.title.score
    end

    should "have matching cover" do
      system("wget -q https://images.immateriel.fr/covers/6EUR43A.thumb.jpg -O /tmp/6EUR43A.jpg")
      assert_equal true, @book.assets.cover.check_file("/tmp/6EUR43A.jpg")
      system("wget -q https://images.immateriel.fr/covers/2NBL7Z5.thumb.jpg -O /tmp/2NBL7Z5.jpg")
      assert_equal false, @book.assets.cover.check_file("/tmp/2NBL7Z5.jpg")
    end

#    should "be bundle" do
#      assert_equal "bundle", @offer.format
#    end
  end

  context "le faiseur d'anges invalid" do
    setup do
      @doc = IMML::Document.new
      @valid = @doc.parse_file("test/fixtures/9781909782471_err.xml",true)
    end

    should "be invalid" do
      assert_equal false, @valid
      assert_equal 1, @doc.errors.length
    end
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

    should "have cover score" do
      assert_equal 0.8, @book.assets.cover.score
    end

    should "have url" do
      assert_equal "http://example.com/9782363761514", @book.url
    end

  end

  context "check 9782366020649 at 3025596562609" do
    setup do
      @doc = IMML::Document.new
      @valid = @doc.parse_file("test/fixtures/check_9782366020649_at_3025596562609.xml",true)
    end

    should "be valid" do
      assert_equal true, @valid
    end

    should "have reseller" do
      assert_equal "3025596562609", @doc.header.reseller.reseller_dilicom_gencod
    end
  end

  context "request 9782366020649 from 3025596562609" do
    setup do
      @doc = IMML::Document.new
      @valid = @doc.parse_file("test/fixtures/request_9782366020649_from_3025596562609.xml",true)
    end

    should "be valid" do
      assert_equal true, @valid
    end

    should "have auth" do
      assert_equal "3025596562609", @doc.header.reseller.reseller_dilicom_gencod
      assert_equal "WoC43KlQX3wg", @doc.header.authentication.api_key
    end
  end


end
