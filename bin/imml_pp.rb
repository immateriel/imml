# -*- coding: utf-8 -*-

require 'imml'
require 'pp'

filename=ARGV[0]

if filename
  doc=IMML::Document.new
  doc.parse_file(filename)

  if doc.book
    puts " Book"
    puts "  Metadata"
    puts "   Title: #{doc.book.metadata.title}"
    puts "   Subtitle: #{doc.book.metadata.subtitle}"
    puts "   Collection: #{doc.book.metadata.collection.name}"
    puts "   Language: #{doc.book.metadata.language}"
    puts "   Publication: #{doc.book.metadata.publication}"
    puts "   Publisher: #{doc.book.metadata.publisher.name}"
    puts "   Contributors"
    doc.book.metadata.contributors.each do |contributor|
      puts "    Contributor: #{contributor.name} (#{contributor.role.role})"
    end
    puts "   Topics"
    doc.book.metadata.topics.each do |topic|
      puts "    Topic: #{topic.identifier} (#{topic.type})"
    end
    puts "   Description: #{doc.book.metadata.description.without_html.with_stripped_spaces}"
    puts "  Assets"
    if doc.book.assets.cover
      puts "   Cover: #{doc.book.assets.cover.url} (#{doc.book.assets.cover.mimetype})"
    end
    if doc.book.assets.extracts.length > 0
      doc.book.assets.extracts.each do |e|
        if e.unsupported?
          puts "   Extract: UNSUPPORTED"
        else
          puts "   Extract: #{e.url} (#{e.mimetype})"
        end
      end
    end
    if doc.book.assets.fulls.length > 0
      doc.book.assets.fulls.each do |f|
        puts "   Full: #{f.url} (#{f.mimetype})"
      end
    end
    puts "  Offer"
    puts "   Medium: #{doc.book.offer.medium}"
    puts "   Format: #{doc.book.offer.format}" if doc.book.offer.format
    puts "   Pagination: #{doc.book.offer.pagination}" if doc.book.offer.pagination
    puts "   Ready for sale: #{doc.book.offer.ready_for_sale}"
    puts "   Sales start at: #{doc.book.offer.sales_start_at}"
    puts "   Prices"
    doc.book.offer.prices.each do |price|
      puts "    Price: #{price.current_amount} #{price.currency} (#{price.territories})"
    end
  end
end