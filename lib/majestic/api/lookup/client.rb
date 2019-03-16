module Majestic
  module Api
    module Lookup
      class Client
        attr_accessor :client, :maximum_items_per_request
        
        def initialize
          self.client                       =   Majestic::Api::Client.new
          self.maximum_items_per_request    =   100
        end
        
        def fetch_seo_data(urls, index = :historic)
          result          =   {}
      
          metric_urls     =   urls.clone
          segments        =   split_into_segments(metric_urls)
      
          segments.each do |segment|
            url_hash      =   make_url_hash(segment)
            urls          =   []

            url_hash.each do |url, values|
              urls << url
            end if (!url_hash.empty?)

            response      =   perform_request(urls, index)

            if response && response.success? && response.items.any?
              response.items.each do |item|
                url_hash.fetch(item.url, {}).merge!({item_info: item})
              end
            end

            url_hash.each do |url, values|
              result[url] = (values[:item_info] && values[:item_info].status && values[:item_info].status.downcase.eql?("found")) ? values : values.merge({item_info: nil})
            end if (!url_hash.empty?)
          end

          return result
        end

        def perform_request(urls, index = :historic, retries = 3)
          urls&.any? ? response = self.client.get_index_item_info(urls: urls, params: {data_source: index}) : nil
        end

        def urls_to_retry(url_hash)
          retry_urls = []

          url_hash.each do |url, values|
            if (values[:item_info] && !values[:item_info].status.downcase.eql?("found"))
              retry_urls << url
            end
          end

          return retry_urls
        end

        private
          def split_into_segments(urls)
            segments      =   []
      
            until (urls.empty?)
              segments   <<   urls.slice!(0..self.maximum_items_per_request)
            end
      
            segments.reject!(&:empty?)
      
            return segments
          end

          def make_url_hash(urls)
            hash          =   {}

            urls.each do |url|
              hash[url]   =   {url: url}
            end if (urls && urls.any?)

            return hash
          end
        
      end
    end
  end
end