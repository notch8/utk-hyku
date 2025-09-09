# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulkrax::FileSetEntryBehaviorDecorator, type: :model, clean: true do
  let(:entry) do
    FactoryBot.create(:bulkrax_csv_entry_file_set)
  end

  it 'uses the locally defined methods' do
    expect(entry.method(:validate_presence_of_filename!).owner).to eq(described_class)
  end

  describe 'updates' do
    context 'without a remote file' do
      let(:attachment) do
        Attachment.create!(
          title: ["Test Attachment title"],
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          state: "complete",
          bulkrax_identifier: 'attachment_1'
        )
      end
      let(:file_set) do
        FileSet.create!(
          title: ['FileSet pre-update'],
          bulkrax_identifier: 'file_set_entry_1'
        )
      end
      let(:entry) do
        Bulkrax::CsvFileSetEntry.create(
          identifier: 'file_set_entry_1',
          type: 'Bulkrax::CsvFileSetEntry',
          importerexporter: FactoryBot.create(:bulkrax_importer),
          raw_metadata: { model: 'FileSet', title: "Updated FileSet title",
                          source_identifier: 'file_set_entry_1', parents: 'attachment_1' },
          parsed_metadata: {}
        )
      end

      before do
        attachment.ordered_members << file_set
        attachment.save!
      end

      around do |example|
        entry
        cached_adapter = ActiveJob::Base.queue_adapter
        cached_perform_enqueued_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
        ActiveJob::Base.queue_adapter = :test
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
        example.run
        ActiveJob::Base.queue_adapter = cached_adapter
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = cached_perform_enqueued_jobs
      end

      it 'does not raise an error' do
        expect(file_set.title).to eq(['FileSet pre-update'])
        expect(file_set.bulkrax_identifier).to eq('file_set_entry_1')
        entry.build_for_importer
        expect(entry.status_message).to eq('Complete')
        expect(entry.error_class).to be_nil
        expect(entry.update?).to be true
        expect(file_set.reload.title).to eq(['Updated FileSet title'])
      end
    end
  end
end
