# frozen_string_literal: true

class CleanupUploadFilesJob < ApplicationJob
  attr_reader :uploads_path
  def perform(days_old:, uploads_path:)
    Rails.logger.info("Starting cleanup coordinator for files older than #{days_old} days")
    @uploads_path = uploads_path
    Rails.logger.info("Spawning #{top_level_directories.count} cleanup jobs for subdirectories")
    top_level_directories.map do |dir|
      CleanupSubDirectoryJob.perform_later(days_old: days_old, directory: dir)
    end
  end

  private

    def top_level_directories
      @top_level_directories ||= Dir.glob("#{uploads_path}/*").select { |path| File.directory?(path) }
    end
end
