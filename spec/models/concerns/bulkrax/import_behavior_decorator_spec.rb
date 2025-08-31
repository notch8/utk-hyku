# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulkrax::ImportBehaviorDecorator, type: :model do
  let(:entry) do
    FactoryBot.create(:bulkrax_csv_entry)
  end

  it 'uses the locally defined methods' do
    expect(entry.method(:add_rights_statement).owner).to eq(described_class)
    expect(entry.method(:build_for_importer).owner).to eq(described_class)
  end

  describe 'updating an attachment' do
    let(:source_identifier) { "1234-5678" }
    let(:generic_work) { FactoryBot.create(:generic_work_with_one_restricted_attachment) }
    let!(:attachment) do
      generic_work.members
                  .select { |member| member.is_a? Attachment }
                  .select { |attachment| attachment.member_of.size == 1 }.first
    end
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:raw_metadata) do
      { model: 'Attachment', title: "Test title", visibility: 'open', source_identifier: source_identifier }
    end
    let(:entry) do
      FactoryBot.create(:bulkrax_csv_entry,
                        identifier: source_identifier,
                        raw_metadata: raw_metadata,
                        parsed_metadata: {})
    end
    let(:last_importer_run) { FactoryBot.create(:bulkrax_importer_run) }

    it 'has the expected visibility' do
      expect(attachment.visibility).to eq('restricted')
      expect(attachment.file_sets.first.visibility).to eq('restricted')
    end

    it 'is updated by the entry' do
      generic_work
      expect(attachment.title).to eq(['Attachment title'])
      expect(attachment.visibility).to eq('restricted')
      allow(entry.importer).to receive(:last_run).and_return(last_importer_run)
      rebuilt_attachment = entry.build_for_importer
      expect(rebuilt_attachment.title).to eq(['Test title'])
      expect(rebuilt_attachment.visibility).to eq('open')
      expect(rebuilt_attachment.file_sets.first.visibility).to eq('open')
    end
  end
end
