# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Attachment`
require 'rails_helper'

RSpec.describe Attachment do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq AttachmentIndexer }
  end

  include_examples "SharedWorkBehavior"
  it_behaves_like 'title validation', 'attachment'

  describe '#intermediate_file?' do
    context 'when rdf_type does not contain intermediate file text' do
      it 'returns false by default' do
        expect(described_class.new.intermediate_file?).to be false
      end
    end

    context 'when rdf_type contains intermediate file text' do
      it 'returns true' do
        attachment = create(:attachment)
        attachment.rdf_type = ['http://pcdm.org/use#IntermediateFile']
        attachment.save

        expect(attachment.intermediate_file?).to be true
      end
    end
  end

  describe '#update' do
    context 'with a connected FileSet' do
      let(:attachment) { FactoryBot.create(:attachment_with_one_file, visibility: 'restricted') }

      it 'updates the visibility of the connected FileSet' do
        expect(attachment.visibility).to eq('restricted')
        expect(attachment.file_sets.first.visibility).to eq('restricted')
        attachment.update!(visibility: 'open')
        expect(attachment.reload.visibility).to eq('open')
        expect(attachment.file_sets.first.reload.visibility).to eq('open')
      end
    end
  end
end
