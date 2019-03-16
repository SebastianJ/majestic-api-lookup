module Majestic
  module Api
    module Lookup
      module Utilities
        class UrlUtility
          
          def self.transform_hostname(hostname, mode = :unicode)
            parsed                          =   PublicSuffix.parse(hostname)
            hostname                        =   "#{parsed.sld}.#{parsed.tld}"
            hostname                        =   !parsed.trd.to_s.empty? ? "#{parsed.trd}.#{hostname}" : hostname
            hostname                        =   SimpleIDN.send("to_#{mode}", hostname).to_s.force_encoding("UTF-8")
          end
          
        end
      end
    end
  end
end
