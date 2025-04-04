# frozen_string_literal: true

# Copied from Hyrax v2.9.0 to add home_text content block to the index method - Adding themes
RSpec.describe Hyrax::HomepageController, type: :controller, clean: true do
  let(:routes) { Hyrax::Engine.routes }

  describe "#index" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'with existing featured researcher' do
      let!(:frodo) do
        ContentBlock.create!(
          name: ContentBlock::NAME_REGISTRY[:researcher],
          value: 'Frodo Baggins',
          created_at: Time.zone.now
        )
      end

      it 'finds the featured researcher' do
        get :index
        expect(response).to be_success
        expect(assigns(:featured_researcher)).to eq frodo
      end
    end

    context 'with no featured researcher' do
      it "sets featured researcher" do
        get :index
        expect(response).to be_success
        assigns(:featured_researcher).tap do |researcher|
          expect(researcher).to be_kind_of ContentBlock
          expect(researcher.name).to eq 'featured_researcher'
        end
      end
    end

    it "sets marketing text" do
      get :index
      expect(response).to be_success
      assigns(:marketing_text).tap do |marketing|
        expect(marketing).to be_kind_of ContentBlock
        expect(marketing.name).to eq 'marketing_text'
      end
    end

    # override hyrax v2.9.0 added @home_text - Adding Themes
    it "sets home page text" do
      get :index
      expect(response).to be_success
      assigns(:home_text).tap do |home|
        expect(home).to be_kind_of ContentBlock
        expect(home.name).to eq 'home_text'
      end
    end

    it "does not include other user's private documents in recent documents" do
      get :index
      expect(response).to be_success
      titles = assigns(:recent_documents).map { |d| d['title_tesim'][0] }
      expect(titles).not_to include('Test Private Document')
    end

    it "includes only GenericWork objects in recent documents" do
      get :index
      assigns(:recent_documents).each do |doc|
        expect(doc["has_model_ssim"]).to eql ["GenericWork"]
      end
    end

    context "with a document not created this second", clean_repo: true do
      before do
        gw3 = GenericWork.new(title: ['Test 3 Document'], read_groups: ['public'])
        gw3.apply_depositor_metadata('mjg36')
        # stubbing to_solr so we know we have something that didn't create in the current second
        old_to_solr = gw3.method(:to_solr)
        allow(gw3).to receive(:to_solr) do
          old_to_solr.call.merge(
            "system_create_dtsi" => 1.day.ago.iso8601,
            "date_uploaded_dtsi" => 1.day.ago.iso8601
          )
        end
        gw3.save
      end

      it "sets recent documents in the right order" do
        get :index
        expect(response).to be_success
        expect(assigns(:recent_documents).length).to be <= 4
        create_times = assigns(:recent_documents).map { |d| d['date_uploaded_dtsi'] }
        expect(create_times).to eq create_times.sort.reverse
      end
    end

    context "with collections" do
      let(:presenter) { double }
      let(:repository) { double }
      let(:collection) { create(:collection) }
      let(:collection_results) { double(documents: [collection]) }

      before do
        allow(controller).to receive(:repository).and_return(repository)
        allow(controller).to receive(:search_results).and_return([nil, ['recent document']])
        allow(controller.repository).to receive(:search).with(an_instance_of(Hyrax::CollectionSearchBuilder))
                                                        .and_return(collection_results)
      end

      it "initializes the presenter with ability and a list of collections" do
        expect(Hyrax::HomepagePresenter).to receive(:new).with(Ability,
                                                               [collection],
                                                               Account)
                                                         .and_return(presenter)
        get :index
        expect(response).to be_success
        expect(assigns(:presenter)).to eq presenter
      end
    end

    context "with featured works" do
      let!(:my_work) { create(:work, user: user) }

      before do
        FeaturedWork.create!(work_id: my_work.id)
      end

      it "sets featured works" do
        get :index
        expect(response).to be_success
        expect(assigns(:featured_work_list)).to be_kind_of FeaturedWorkList
      end
    end

    it "sets announcement content block" do
      get :index
      expect(response).to be_success
      assigns(:announcement_text).tap do |announcement|
        expect(announcement).to be_kind_of ContentBlock
        expect(announcement.name).to eq 'announcement_text'
      end
    end

    xcontext "without solr" do # skip until and fix with ticket #148 https://github.com/notch8/palni-palci/issues/148
      before do
        allow(controller).to receive(:repository).and_return(instance_double(Blacklight::Solr::Repository))
        allow(controller.repository).to receive(:search).and_raise Blacklight::Exceptions::InvalidRequest
      end

      it "errors gracefully" do
        get :index
        expect(response).to be_success
        expect(assigns(:admin_sets)).to be_blank
        expect(assigns(:recent_documents)).to be_blank
      end
    end

    context 'with theming' do
      it { is_expected.to use_around_action(:inject_theme_views) }
    end

    context 'with ir stats' do
      before do
        allow(controller).to receive(:home_page_theme).and_return('institutional_repository')
      end
      # rubocop:disable RSpec/LetSetup
      let!(:work_with_resource_type) { create(:work, user: user, resource_type: ['Article']) }

      # rubocop:enable RSpec/LetSetup

      it 'gets the stats' do
        get :index
        expect(response).to be_success
        expect(assigns(:ir_counts)['facet_counts']['facet_fields']['resource_type_sim']).to include('Article', 1)
      end
    end
  end
end
