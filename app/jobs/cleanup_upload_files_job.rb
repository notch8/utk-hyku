# frozen_string_literal: true

# Kicks off jobs for each sub-directory in a given directory to clear out unneeded uploads
class CleanupUploadFilesJob < ApplicationJob
  non_tenant_job

  attr_reader :uploads_path
  def perform(delete_ingested_after_days:, uploads_path:, delete_all_after_days: 730)
    @uploads_path = uploads_path
    logger.info(message(delete_ingested_after_days, delete_all_after_days))
    top_level_directories.map do |dir|
      CleanupSubDirectoryJob.perform_later(
        delete_ingested_after_days: delete_ingested_after_days,
        directory: dir,
        delete_all_after_days: delete_all_after_days
      )
    end
  end

  private

    def top_level_directories
      @top_level_directories ||= Dir.glob("#{uploads_path}/*").select { |path| File.directory?(path) }
    end

    def message(delete_ingested_after_days, delete_all_after_days)
      <<~MESSAGE
        Starting cleanup: delete ingested after #{delete_ingested_after_days} days,
        delete all files after #{delete_all_after_days} days.
        Spawning #{top_level_directories.count} cleanup jobs for subdirectories
      MESSAGE
    end
end
