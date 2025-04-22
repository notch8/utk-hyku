# frozen_string_literal: true

class UriCache < ApplicationRecord
  validates :uri, presence: true, uniqueness: true
end
