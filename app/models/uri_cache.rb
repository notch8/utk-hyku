# frozen_string_literal: true

class UriCache < ApplicationRecord
  validates :uri, presence: true, uniqueness: true
  validates :value, presence: true

  def update_cache
    value = UriToStringConverterService.uri_to_value_for(uri, fetch_from_remote: true)
    update(value: value)
  end

  def self.update_all_caches!
    find_each(&:update_cache)
  end

  # Allow for something like UriCache.create('http://id.loc.gov/authorities/names/n2017180154')
  def self.create(uri:, value: nil)
    transaction do
      return super(uri: uri, value: value) if uri.present? && value.present?

      fetched_value = UriToStringConverterService.uri_to_value_for(uri)
      raise StandardError, fetched_value if fetched_value.include?(uri)

      super(uri: uri, value: fetched_value)
    end
  end
end
