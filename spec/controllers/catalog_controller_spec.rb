# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  describe "GET /show" do
    let(:file_set) { create(:file_set) }

    context "with access" do
      before do
        sign_in create(:user)
        allow(controller).to receive(:can?).and_return(true)
      end

      it "is successful" do
        get :show, params: { id: file_set }
        expect(response).to be_successful
        expect(response.content_type).to eq 'application/json'
      end
    end

    context "without access" do
      it "is redirects to sign in" do
        get :show, params: { id: file_set }
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe "facet configuration" do
    let(:config) { described_class.blacklight_config }
    let(:facet_fields) { config.facet_fields }

    it "configures facet fields with correct limits" do
      expect(facet_fields['human_readable_type_sim'].limit).to eq 5
      expect(facet_fields['creator_sim'].limit).to eq 5
      expect(facet_fields['contributor_sim'].limit).to eq 5
      expect(facet_fields['keyword_sim'].limit).to eq 5
      expect(facet_fields['subject_sim'].limit).to eq 5
      expect(facet_fields['language_sim'].limit).to eq 5
      expect(facet_fields['based_near_label_sim'].limit).to eq 5
      expect(facet_fields['publisher_sim'].limit).to eq 5
      expect(facet_fields['file_format_sim'].limit).to eq 5
      expect(facet_fields['form_local_sim'].limit).to eq 5
      expect(facet_fields['intermediate_provider_sim'].limit).to eq 5
      expect(facet_fields['license_sim'].limit).to eq 5
      expect(facet_fields['resource_type_sim'].limit).to eq 5
      expect(facet_fields['member_of_collections_sim'].limit).to eq 5
      expect(facet_fields['spatial_sim'].limit).to eq 5
    end

    it "configures facet fields with correct labels" do
      expect(facet_fields['date_created_d_sim'].label).to eq 'Date Created'
      expect(facet_fields['contributor_sim'].label).to eq 'Contributor'
      expect(facet_fields['form_local_sim'].label).to eq 'Form'
      expect(facet_fields['intermediate_provider_sim'].label).to eq 'Intermediate Provider'
      expect(facet_fields['license_sim'].label).to eq 'License'
      expect(facet_fields['resource_type_sim'].label).to eq 'Resource Type'
      expect(facet_fields['rights_statement_sim'].label).to eq 'Rights Statement'
      expect(facet_fields['member_of_collections_sim'].label).to eq 'Collections'
      expect(facet_fields['spatial_sim'].label).to eq 'Location'
    end

    describe "facet more options" do
      before do
        # Clean the database before running this test
        GenericWork.destroy_all

        # Create 7 works with different form values
        7.times do |i|
          create(:generic_work, form_local: ["Form #{i}"])
        end
      end

      it "shows more button when there are more items than the display limit" do
        get :index
        expect(response).to be_successful

        facet_response = assigns(:response)
        form_facet = facet_response.aggregations['form_local_sim']

        # Blacklight looks for limit + 1 items (5 + 1 = 6) to determine whether to show the more button
        expect(form_facet.items.length).to eq 6
        # Verify the configured limit is 5
        expect(facet_fields['form_local_sim'].limit).to eq 5
        # Verify there are more items than shown
        expect(form_facet.items.length).to eq(facet_fields['form_local_sim'].limit + 1)
      end
    end
  end
end
