# frozen_string_literal: true

namespace :hyku do
  desc 'update cached URIs with remote authority'
  task update_cached_uris: :environment do
    UriCache.update_all_caches!
  end
end
