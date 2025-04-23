# frozen_string_literal: true

FactoryBot.define do
  factory :uri_cache do
    uri { 'https://id.loc.gov/authorities/names/n79007751' }
    value { 'University of Tennessee' }
  end
end
