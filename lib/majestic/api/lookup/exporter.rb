module Majestic
  module Api
    module Lookup
      
      class Exporter
        attr_accessor :client, :data

        def initialize
          self.client                     =   ::Majestic::Api::Lookup::Client.new
          self.data                       =   {}
        end

        def analyze(domains:, output_path:)
          domains.map! { |domain| domain.strip }.uniq!

          majestic_historic_data          =   self.client.fetch_seo_data(domains, :historic)
          majestic_fresh_data             =   self.client.fetch_seo_data(domains, :fresh)

          urls                            =   domains.map { |domain| Majestic::Api::Lookup::Utilities::UrlUtility.transform_hostname(domain.strip, :unicode) }

          domains.each do |domain|
            url                           =   Majestic::Api::Lookup::Utilities::UrlUtility.transform_hostname(domain.strip, :unicode)
            tld                           =   PublicSuffix.parse(url).tld

            historic                      =   majestic_historic_data[domain]
            fresh                         =   majestic_fresh_data[domain]

            puny_coded                    =   Majestic::Api::Lookup::Utilities::UrlUtility.transform_hostname(url, :ascii)

            values                        =   {
              url:                        url,
              tld:                        tld,
              historic_backlinks:         historic[:item_info]&.external_backlinks,
              historic_referring_domains: historic[:item_info]&.referring_domains,
              historic_c_class_subnets:   historic[:item_info]&.referring_subnets,
              historic_trust_flow:        historic[:item_info]&.trust_flow,
              historic_citation_flow:     historic[:item_info]&.citation_flow,
              fresh_trust_flow:           fresh[:item_info]&.trust_flow,
              fresh_citation_flow:        fresh[:item_info]&.citation_flow,
            }
  
            values.each do |key, value|
              self.data[domain]         ||=   {}
              self.data[domain][key]      =   !value.nil? ? value : ""
            end
          end

          export_to_file(output_path)
        end

        def export_to_file(output_path)
          unless self.data.empty?
            FileUtils.rm_rf output_path if File.exists?(output_path)
  
            headers   =   [
              "Domain",
              "TLD"
            ]
  
            headers   =  headers + [
              "Majestic Historic Backlinks",
              "Majestic Historic Referring Domains",
              "Majestic Historic C-class Subnets",
              "Majestic Historic Trust Flow",
              "Majestic Fresh Trust Flow",
              "Majestic Historic Citation Flow",
              "Majestic Fresh Citation Flow"
            ]
  
            CSV.open(output_path, "w") do |csv|
              csv << headers
    
              self.data.each do |domain, seo_data|
                row   =   [
                  domain,
                  seo_data[:tld]
                ]
      
                row   =   row + [
                  seo_data[:historic_backlinks],
                  seo_data[:historic_referring_domains],
                  seo_data[:historic_c_class_subnets],
                  seo_data[:historic_trust_flow],
                  seo_data[:fresh_trust_flow],
                  seo_data[:historic_citation_flow],
                  seo_data[:fresh_citation_flow]
                ]
      
                csv << row
              end
            end
          end
        end
      end
      
    end
  end
end