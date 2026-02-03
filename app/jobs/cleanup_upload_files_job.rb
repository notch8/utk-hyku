# frozen_string_literal: true

class CleanupUploadFilesJob < ApplicationJob
  non_tenant_job

  attr_reader :uploads_path, :days_old, :very_old_days
  def perform(days_old:, uploads_path:, very_old_days: 730)
    @days_old = days_old
    @uploads_path = uploads_path
    @very_old_days = very_old_days
    Rails.logger.info("Starting cleanup coordinator for files older than #{days_old} days (very_old: #{very_old_days} days)")
    Rails.logger.info("Spawning #{top_level_directories.count} cleanup jobs for subdirectories")
    top_level_directories.map do |dir|
      CleanupSubDirectoryJob.perform_later(days_old: days_old, directory: dir, very_old_days: very_old_days)
    end
  end

  private

    def top_level_directories
      @top_level_directories ||= Dir.glob("#{uploads_path}/*").select { |path| File.directory?(path) }
    end
end
