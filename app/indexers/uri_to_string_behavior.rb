# frozen_string_literal: true

module UriToStringBehavior
  extend ActiveSupport::Concern

  # UTK uses this label to house the value that needs to be rendered
  LABEL = "http://www.w3.org/2004/02/skos/core#prefLabel"

  # Retrieves a value for a given URI.
  #
  # @param value [String] the value to retrieve. If this value starts with 'http', it is treated as a URI.
  # @return [String]
  #
  # @example
  #   uri_to_value_for('http://example.com') #=> "Failed to load RDF data: ..."
  #   uri_to_value_for('http://id.loc.gov/authorities/names/n2017180154') #=> "University of Tennessee"
  #   uri_to_value_for('Doe, John') #=> "Doe, John"
  def uri_to_value_for(value)
    return value.map { |v| uri_to_value_for(v) } if value.is_a?(Enumerable)
    return if value.blank?
    return value unless value.is_a?(String)
    return value unless value.start_with?('http')

    uri = value

    begin
      graph = RDF::Graph.load(uri)
    rescue StandardError => e
      Rails.logger.error("Failed to load RDF data: #{e.message}")
      return "#{uri} (Failed to load URI)"
    end

    subject = RDF::URI.new(uri)
    predicate = RDF::URI.new(LABEL)
    object = graph.query([subject, predicate, nil]).objects.first
    return "#{uri} (No label found)" if object.blank?

    object.to_s
  end
end
