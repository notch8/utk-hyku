# frozen_string_literal: true

class UriToStringConverterService
  # UTK uses this label to house the value that needs to be rendered
  DEFAULT_LABEL = "http://www.w3.org/2004/02/skos/core#prefLabel"

  attr_reader :object

  def initialize(object)
    @object = object
  end

  # Converts URIs to their corresponding values for a list of fields.
  # @todo We should consider storing the strings into a database record every time we find an new one
  #   for future queries, we would check the local database first and if it's not there, go out and
  #   check the remote authority.  This would cut down reindexing speeds over time.
  #
  # @param fields [Array<Symbol>] list of property names to process
  # @param found_mappings [Hash] cache of previously resolved URI values to avoid redundant HTTP requests
  # @return [Array<String>] flattened array of resolved values with blanks removed
  #
  # @example Without cache
  #   convert_uri_to_value(['creator', 'contributor'])
  #   #=> ["University of Tennessee", "John Doe"]
  #
  # @example With cached values
  #   mappings = { creator: ["University of Tennessee"] }
  #   convert_uri_to_value(['creator', 'contributor'], found_mappings: mappings)
  #   #=> ["University of Tennessee", "John Doe"] # creator used cache, contributor made HTTP request
  def convert_uri_to_value(fields, found_mappings: {})
    return [] if fields.blank?

    fields.flat_map do |prop|
      found_mappings[prop.to_sym] || uri_to_value_for(object.try(prop))
    end.compact
  end

  def uri_to_value_for(prop)
    self.class.uri_to_value_for(prop)
  end

  class << self
    # Retrieves a value for a given URI.
    #
    # @param value [String] the value to retrieve. If this value starts with 'http', it is treated as a URI.
    # @return [String]
    #
    # @example
    #   uri_to_value_for('http://example.com') #=> "Failed to load RDF data: ..."
    #   uri_to_value_for('http://id.loc.gov/authorities/names/n2017180154') #=> "University of Tennessee"
    #   uri_to_value_for('Doe, John') #=> "Doe, John"
    # rubocop:disable Metrics/CyclomaticComplexity
    def uri_to_value_for(uri, fetch_from_remote: false)
      return uri.map { |v| uri_to_value_for(v) } if uri.is_a?(Enumerable)
      return if uri.blank?
      return uri unless uri.is_a?(String) && uri.start_with?('http')

      # Checks QA instead of reaching out to a server
      local_value = get_local_uri_value(uri)
      return local_value if local_value.present?

      # Check the database cache
      cached = fetch_from_remote == true ? nil : UriCache.find_by(uri: uri)
      return cached.value if cached.present?

      # Handle different URI patterns
      modified_uri, subject_uri, predicate = extract_rdf_components(uri)

      begin
        graph = RDF::Graph.load(modified_uri, headers: { 'Accept' => 'application/rdf+xml' })
      rescue StandardError => e
        Rails.logger.error("Failed to load RDF data: #{e.message}")
        return "#{uri} (Failed to load URI)"
      end

      subject = RDF::URI.new(subject_uri)
      objects = graph.query([subject, predicate, nil]).objects
      object = objects.find do |o|
        o.language == :en || o.language == :'en-us' || o.language.nil?
      end || objects.sort_by(&:value).first
      return "#{uri} (No label found)" if object.blank?

      value = object.to_s
      UriCache.create(uri: uri, value: value) # save for future use

      value
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private

      def get_local_uri_value(uri)
        if uri.start_with?('http://rightsstatements.org/')
          rights_term_for(uri)
        elsif uri.start_with?('http://creativecommons.org/')
          license_term_for(uri)
        end
      end

      # Extracts components needed for RDF querying based on the URI pattern.
      # Handles special cases for Getty, GeoNames URIs, and RightsStatement.org,
      # adjusting the URI format and selecting the appropriate predicate for label
      # retrieval.
      #
      # @param uri [String] the URI to process
      # @return [Array<String, String, RDF::URI>] returns an array containing:
      #   - The processed URI for loading RDF data
      #   - The subject URI for querying the graph
      #   - The predicate URI for finding the label
      #
      # @example Library of Congress URI
      #   extract_rdf_components('https://id.loc.gov/authorities/names/n2017180154')
      #   #=> ['https://id.loc.gov/authorities/names/n2017180154',
      #        'http://id.loc.gov/authorities/names/n2017180154',
      #        #<RDF::URI:0x... URI:http://www.w3.org/2004/02/skos/core#prefLabel>]
      #
      # @example Getty URI
      #   extract_rdf_components('https://vocab.getty.edu/page/ulan/500026846')
      #   #=> ['https://vocab.getty.edu/ulan/500026846',
      #        'http://vocab.getty.edu/ulan/500026846',
      #        #<RDF::URI:0x... URI:http://www.w3.org/2004/02/skos/core#prefLabel>]
      #
      # @example GeoNames URI
      #   extract_rdf_components('http://sws.geonames.org/4509884')
      #   #=> ['http://sws.geonames.org/4509884/about.rdf',
      #        'https://sws.geonames.org/4509884/',
      #        #<RDF::URI:0x... URI:http://www.geonames.org/ontology#name>]
      #
      # @example RightsStatement.org URI
      #   extract_rdf_components('http://rightsstatements.org/vocab/InC/1.0/')
      #   #=> ['https://rightsstatements.org/data/InC/1.0.ttl',
      #        'http://rightsstatements.org/vocab/InC/1.0/',
      #        #<RDF::URI:0x... URI:http://www.w3.org/2004/02/skos/core#prefLabel>]
      #
      # @example Creative Commons URI
      #   extract_rdf_components('https://creativecommons.org/licenses/by/4.0/')
      #   #=> ['https://creativecommons.org/licenses/by/4.0/rdf',
      #        'https://creativecommons.org/licenses/by/4.0/',
      #        #<RDF::URI:0x... URI:http://purl.org/dc/terms/title>]
      #
      # @example Wikidata URI
      #   extract_rdf_components('https://www.wikidata.org/entity/Q85304029')
      #   #=> ['http://www.wikidata.org/entity/Q85304029.nt',
      #        'http://www.wikidata.org/entity/Q85304029',
      #        #<RDF::URI:0x... URI:http://www.w3.org/2004/02/skos/core#prefLabel>]
      #
      # @example Homosaurus URI
      #   extract_rdf_components('https://homosaurus.org/v3/homoit0000070')
      #   #=> ['https://homosaurus.org/v3/homoit0000070.nt',
      #        'https://homosaurus.org/v4/homoit0000070',
      #        #<RDF::URI:0x... URI:http://www.w3.org/2004/02/skos/core#prefLabel>]
      #
      # Extracts components needed for RDF querying based on the URI pattern.
      # @param uri [String] the URI to process
      # @return [Array<String, String, RDF::URI>] processed URI, subject URI, and predicate URI
      # rubocop:disable Metrics/MethodLength
      def extract_rdf_components(uri)
        uri_handlers = {
          'id.loc.gov' => lambda { |input_uri|
            subject_uri = input_uri.gsub('https://', 'http://')
            [input_uri, subject_uri, RDF::URI(DEFAULT_LABEL)]
          },

          'vocab.getty.edu' => lambda { |input_uri|
            modified_uri = input_uri.gsub('/page/', '/')
            subject_uri = modified_uri.gsub('https://', 'http://')
            [modified_uri, subject_uri, RDF::URI(DEFAULT_LABEL)]
          },

          'sws.geonames.org' => lambda { |input_uri|
            input_uri = input_uri.chomp('/')
            modified_uri = "#{input_uri}/about.rdf"
            subject_uri = "#{input_uri.gsub('http://', 'https://')}/"
            [modified_uri, subject_uri, RDF::URI("http://www.geonames.org/ontology#name")]
          },

          'rightsstatements.org' => lambda { |input_uri|
            modified_uri = "#{input_uri.chomp('/').gsub('http://', 'https://').gsub('/vocab/', '/data/')}.ttl"
            [modified_uri, input_uri, RDF::URI(DEFAULT_LABEL)]
          },

          'creativecommons.org' => lambda { |input_uri|
            modified_uri = input_uri + 'rdf'
            [modified_uri, input_uri, RDF::URI('http://purl.org/dc/terms/title')]
          },

          'wikidata.org' => lambda { |input_uri|
            modified_uri = "#{input_uri.gsub('https://', 'http://')}.nt"
            subject_uri = input_uri.gsub('https://', 'http://')
            [modified_uri, subject_uri, RDF::URI(DEFAULT_LABEL)]
          },

          'homosaurus.org' => lambda { |input_uri|
            modified_uri = "#{input_uri}.nt"
            subject_uri = input_uri.gsub('/v3/', '/v4/') # looks like the rdf falls back to v4
            [modified_uri, subject_uri, RDF::URI(DEFAULT_LABEL)]
          }
        }

        # Find the matching handler or use default
        handler_key = uri_handlers.keys.find { |key| uri.include?(key) }

        if handler_key
          uri_handlers[handler_key].call(uri)
        else
          [uri, uri, RDF::URI(DEFAULT_LABEL)]
        end
      end
      # rubocop:enable Metrics/MethodLength

      def rights_term_for(uri)
        Qa::Authorities::Local.subauthority_for('rights_statements').find(uri).fetch(:term, nil)
      end

      def license_term_for(uri)
        Qa::Authorities::Local.subauthority_for('licenses').find(uri).fetch(:term, nil)
      end
  end
end
