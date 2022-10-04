# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    if example.metadata[:allinson_flex_admin_set]
      AdminSet.find_or_create_default_admin_set_id
      if AllinsonFlex::Profile.count <= 0
        @allinson_flex_profile = AllinsonFlex::Importer.load_profile_from_path(path: Rails.root.join('config',
                                                                                                     'metadata_profile', 'hyrax.yml'))
        @allinson_flex_profile.save
      end
    end
  end
end
