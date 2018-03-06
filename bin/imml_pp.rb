# -*- coding: utf-8 -*-

require 'imml'
require 'pp'

filename=ARGV[0]

if filename
  doc=IMML::Document.new
  if doc.parse_file(filename)

    puts "Version: #{doc.version}"

    if doc.book
      puts " Book"
      puts "  EAN: #{doc.book.ean}"
      puts "  Metadata"
      puts "   Title: #{doc.book.metadata.title}"
      puts "   Subtitle: #{doc.book.metadata.subtitle}"
      if doc.book.metadata.collection
        puts "   Collection: #{doc.book.metadata.collection.name}"
      end
      if doc.book.metadata.language.unsupported?
        puts "   Language: UNSUPPORTED"
      else
        puts "   Language: #{doc.book.metadata.language}"
      end
      puts "   Publication: #{doc.book.metadata.publication}"
      puts "   Publisher: #{doc.book.metadata.publisher.name}"
      if doc.book.metadata.imprint
        puts "   Imprint: #{doc.book.metadata.imprint.name}"
      end
      puts "   Contributors"
      doc.book.metadata.contributors.each do |contributor|
        puts "    Contributor: #{contributor.name} (#{contributor.role.role})"
      end
      puts "   Topics"
      doc.book.metadata.topics.each do |topic|
        if topic.unsupported?
          puts "    Topic: UNSUPPORTED (#{topic.type})"
        else
          puts "    Topic: #{topic.identifier} (#{topic.type})"
        end
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
          if f.unsupported?
            puts "   Full: UNSUPPORTED"
          else
            puts "   Full: #{f.url} (#{f.mimetype})"
          end
        end
      end
      puts "  Offer"
      puts "   Medium: #{doc.book.offer.medium}"
      puts "   Pagination: #{doc.book.offer.pagination}" if doc.book.offer.pagination
      puts "   Ready for sale: #{doc.book.offer.ready_for_sale}"
      if doc.book.offer.sales_start_at
        puts "   Sales start at: #{doc.book.offer.sales_start_at.date}"
      end
      puts "   Sales models"
      doc.book.offer.sales_models.each do |sale_model|
        puts "    Sales model"
        puts "     Type: #{sale_model.type}"
        puts "     Available: #{sale_model.available}"
        puts "     Customer: #{sale_model.customer}"
        puts "     Format: #{sale_model.format}"
        puts "     Protection: #{sale_model.protection}"
      end
      puts "   Prices"
      doc.book.offer.prices.each do |price|
        puts "    Price: #{price.current_amount} #{price.currency} (#{price.territories})"
      end
    end
  end

end