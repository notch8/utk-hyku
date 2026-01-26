# frozen_string_literal: true

class NestedWorkReindexJob < ApplicationJob
  queue_as :import

  def perform(id:)
    work = ActiveFedora::Base.find(id)

    # Update attachments' file sets
    work.members.each do |attachment|
      attachment.file_sets.each(&:update_index)
    end

    # update attachments
    work.members.each(&:update_index)

    # update work
    work.update_index
  end
end
