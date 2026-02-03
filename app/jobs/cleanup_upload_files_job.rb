# frozen_string_literal: true

class CleanupUploadFilesJob < ApplicationJob
  non_tenant_job

  attr_reader :uploads_path, :delete_ingested_after_days, :delete_orphaned_after_days
  def perform(delete_ingested_after_days:, uploads_path:, delete_orphaned_after_days: 730)
    @delete_ingested_after_days = delete_ingested_after_days
    @uploads_path = uploads_path
    @delete_orphaned_after_days = delete_orphaned_after_days
    Rails.logger.info("Starting cleanup: delete ingested after #{delete_ingested_after_days} days, delete orphaned after #{delete_orphaned_after_days} days")
    Rails.logger.info("Spawning #{top_level_directories.count} cleanup jobs for subdirectories")
    top_level_directories.map do |dir|
      CleanupSubDirectoryJob.perform_later(
        delete_ingested_after_days: delete_ingested_after_days,
        directory: dir,
        delete_orphaned_after_days: delete_orphaned_after_days
      )
    end
  end

  private

    def top_level_directories
      @top_level_directories ||= Dir.glob("#{uploads_path}/*").select { |path| File.directory?(path) }
    end
end
