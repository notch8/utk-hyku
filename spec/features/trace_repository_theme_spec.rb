# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select trace repository theme', type: :feature, js: true, clean: true do
  let(:account) { create(:account) }
  let(:admin) { create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:user) { create :user }

  # rubocop:disable RSpec/LetSetup
  let!(:work) do
    create(:generic_work,
           title: ['Llamas and Alpacas'],
           keyword: ['llama', 'alpaca'],
           user: user)
  end

  # rubocop:enable RSpec/LetSetup

  context "as a repository admin" do
    it 'sets the trace repository theme when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Cultural Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      expect(site.home_theme).to eq('trace_repository')
    end
  end
end
