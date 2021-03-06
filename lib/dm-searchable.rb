require 'rubygems'
gem 'dm-core', '>=0.9.2'
require 'dm-core'

dir = Pathname(__FILE__).dirname.expand_path / 'dm-searchable'

module DataMapper
  module Searchable
    def self.included(base)
      base.extend(ClassMethods)
    end
   
    module ClassMethods
      def is_searchable(*fields)
        if fields.length > 0
          @searchable_fields = fields
        else
          @searchable_fields = properties.reject {|p| p.key? }.map {|p| p.name}
        end
      end
    end
    
    module SearchMethods
      def search(query = "", options = {})
        case_insensitive = true unless case_insensitive = options.delete(:case)
        query = query.split(/\s+/) if query

        # Now build the SQL for the search if there is text to search for
        condition_list = []
        unless query.empty?
          text_condition = if case_insensitive
            query.map do |t|
              s = searchable_fields.map { |f| condition_list << "%#{t.downcase}%"; "LOWER(#{f.to_s}) LIKE ?" }
              "(#{s.join " OR "})"
            end
          else
            query.map do |t|
              s = searchable_fields.map { |f| condition_list << "%#{t}%"; "#{f.to_s} LIKE ?" }
              "(#{s.join " OR "})"
            end
          end.join " AND "

          # Add the text search term's SQL to the conditions string unless
          # the text was nil to begin with.
          condition_list = [text_condition] + condition_list
        end
        if self.query
          options = self.query.merge(options)
        end
        unless condition_list.empty?
          options = options.merge(:conditions => condition_list)
        end
        all(options)
      end
    end
  end
end

require dir / 'collection'
require dir / 'model'
require dir / 'proxy'