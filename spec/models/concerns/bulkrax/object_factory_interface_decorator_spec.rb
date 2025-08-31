# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulkrax::ObjectFactoryInterfaceDecorator, type: :model do
  let(:factory) do
    Bulkrax.object_factory.new(
      attributes: attributes,
      source_identifier_value: "1234-5678",
      work_identifier: :bulkrax_identifier,
      work_identifier_search_field: 'bulkrax_identifier_sim',
      update_files: true,
      klass: Attachment
    )
  end
  let(:attributes) { {} }

  it 'uses the locally defined methods' do
    expect(factory.method(:update).owner).to eq(described_class)
  end

  describe 'updating an Attachment' do
    let(:generic_work) { FactoryBot.create(:generic_work_with_one_restricted_attachment) }
    let!(:attachment) do
      generic_work.members
                  .select { |member| member.is_a? Attachment }
                  .select { |attachment| attachment.member_of.size == 1 }.first
    end
    let(:attributes) do
      {
        "bulkrax_identifier" => "1234-5678",
        "model" => "Attachment",
        "title" => ["Test title"],
        "visibility" => "open",
        "file" => [],
        "admin_set_id" => "admin_set/default"
      }
    end

    it 'can update an object' do
      expect(attachment.title).to eq(['Attachment title'])
      expect(attachment.visibility).to eq('restricted')
      expect(attachment.file_sets.first.visibility).to eq('restricted')
      allow(factory).to receive(:find).and_return(attachment)
      factory.run!
      expect(attachment.title).to eq(['Test title'])
      expect(attachment.visibility).to eq('open')
      expect(attachment.file_sets.first.visibility).to eq('open')
    end
  end
end
