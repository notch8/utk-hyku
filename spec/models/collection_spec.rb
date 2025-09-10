# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection do
  let(:user) { create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
  let(:account) { create(:account) }
  let(:collection) { create(:collection, user: user) }

  before do
    Site.update(account: account)
  end

  it 'is a hyrax collection' do
    expect(described_class.ancestors).to include Hyrax::CollectionBehavior
  end

  describe '.indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq CollectionIndexer }
  end

  context 'metadata properties' do
    subject { build :collection }

    let(:collection) { build(:collection) }

    it { is_expected.to have_property(:abstract).with_predicate('http://purl.org/dc/terms/abstract') }
    it {
      is_expected.to have_property(:bulkrax_identifier)
        .with_predicate('https://hykucommons.org/terms/bulkrax_identifier')
    }
    it { is_expected.to have_property(:contributor).with_predicate('http://id.loc.gov/vocabulary/relators/ctb') }
    it { is_expected.to have_property(:creator).with_predicate('http://id.loc.gov/vocabulary/relators/cre') }
    it { is_expected.to have_property(:date_created).with_predicate('http://purl.org/dc/terms/created') }
    it { is_expected.to have_property(:date_created_d).with_predicate('https://dbpedia.org/ontology/completionDate') }
    it { is_expected.to have_property(:date_issued).with_predicate('http://purl.org/dc/terms/issued') }
    it { is_expected.to have_property(:date_issued_d).with_predicate('https://dbpedia.org/ontology/publicationDate') }
    it { is_expected.to have_property(:extent).with_predicate('http://rdaregistry.info/Elements/u/P60550') }
    it { is_expected.to have_property(:form).with_predicate('http://purl.org/dc/terms/format') }
    it { is_expected.to have_property(:keyword).with_predicate('https://w3id.org/idsa/core/keyword') }
    it { is_expected.to have_property(:note).with_predicate('http://www.w3.org/2004/02/skos/core#note') }
    it { is_expected.to have_property(:publication_place).with_predicate('https://id.loc.gov/vocabulary/relators/pup') }
    it { is_expected.to have_property(:publisher).with_predicate('http://id.loc.gov/vocabulary/relators/pbl') }
    it { is_expected.to have_property(:repository).with_predicate('http://id.loc.gov/vocabulary/relators/rps') }
    it { is_expected.to have_property(:resource_link).with_predicate('http://www.europeana.eu/schemas/edm/isShownAt') }
    it { is_expected.to have_property(:resource_type).with_predicate('http://purl.org/dc/terms/type') }
    it { is_expected.to have_property(:spatial).with_predicate('http://purl.org/dc/terms/spatial') }
    it { is_expected.to have_property(:subject).with_predicate('http://purl.org/dc/terms/subject') }
    it { is_expected.to have_property(:title).with_predicate('http://purl.org/dc/terms/title') }
    it { is_expected.to have_property(:utk_contributor).with_predicate('https://ontology.lib.utk.edu/roles#ctb') }
    it { is_expected.to have_property(:utk_creator).with_predicate('https://ontology.lib.utk.edu/roles#cre') }
    it { is_expected.to have_property(:utk_publisher).with_predicate('https://ontology.lib.utk.edu/roles#pbl') }
  end

  describe 'Featured Collections' do
    before do
      FeaturedCollection.create(collection_id: collection.id)
    end

    describe '#update' do
      context 'when collection is public' do
        let(:collection) { create(:public_collection) }

        it 'does not remove the collection from featured collections' do
          expect(collection).not_to receive(:remove_featured)
          collection.update(title: ['New collection title'])
        end
      end

      context 'when collection is private' do
        let(:collection) { create(:private_collection) }

        it 'removes collection from featured collections' do
          expect(collection).to receive(:remove_featured)
          collection.update(title: ['New collection title'])
        end
      end

      context 'when collection is changed from public to private' do
        let(:collection) { create(:public_collection) }

        it 'removes collection from featured collections' do
          expect(collection).to receive(:remove_featured)
          collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          collection.save!
        end
      end
    end

    describe '#destroy' do
      it 'deletes the featured collection after destroying the collection' do
        expect(collection).to receive(:remove_featured)
        collection.destroy
      end
    end

    describe '#remove_featured' do
      it 'removes collection from featured collections' do
        expect(FeaturedCollection.where(collection_id: collection.id).count).to eq(1)
        collection.remove_featured
        expect(FeaturedCollection.where(collection_id: collection.id).count).to eq(0)
      end
    end
  end

  describe 'reindex_member_objects' do
    let(:work) { create(:generic_work) }

    before do
      work.member_of_collections << collection
      work.save
      collection.title = ['New title']

      perform_enqueued_jobs do
        collection.save
      end
    end

    it 'reindexes its works' do
      expect(SolrDocument.find(work.id)['member_of_collections_ssim']).to eq ['New title']
    end
  end
end
