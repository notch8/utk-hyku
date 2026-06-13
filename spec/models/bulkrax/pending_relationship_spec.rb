# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulkrax::PendingRelationship do
  describe 'failure status denormalization' do
    let(:importer_run) { FactoryBot.create(:bulkrax_importer_run) }
    let(:pending_relationship) do
      described_class.create!(
        importer_run_id: importer_run.id,
        parent_id: 'parent',
        child_id: 'child',
        order: 0
      )
    end

    it 'records a failed status without raising for the denormalized error_class column' do
      expect do
        pending_relationship.set_status_info(StandardError.new('error'), importer_run)
      end.not_to raise_error
    end
  end
end
