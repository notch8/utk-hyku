# frozen_string_literal: true

class CleanupSubDirectoryJob < ApplicationJob
  non_tenant_job

  attr_reader :days_old, :directory
  def perform(days_old:, directory:)
    @directory = directory
    @days_old = days_old
    @files_checked = 0
    @files_deleted = 0
    delete_files
    delete_empty_directories
    logger.info("Completed #{directory}: checked #{@files_checked}, deleted #{@files_deleted}")
  end

  private

    def delete_files
      Dir.glob("#{directory}/**/*").each do |path|
        next unless should_be_deleted?(path)

        File.delete(path)
        @files_deleted += 1
        logger.info("Checked #{@files_checked}, deleted #{@files_deleted} files") if (@files_checked % 100).zero?
      end
    end

    def delete_empty_directories
      # Find all UUID-level directories (deepest level)
      Dir.glob("#{directory}/*/*/*/*/*").select { |d| File.directory?(d) }.each do |dir|
        begin
          FileUtils.rmdir(dir, parents: true)
        rescue Errno::ENOTEMPTY
          next
        end
      end

      logger.info("Completed empty directory cleanup for #{directory}")
    end

    def should_be_deleted?(path)
      return false unless File.file?(path)

      @files_checked += 1
      old_enough?(path)
    end

    def old_enough?(path)
      File.mtime(path) < (Time.zone.now - days_old.to_i.days)
    end
end
