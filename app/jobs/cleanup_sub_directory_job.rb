# frozen_string_literal: true

class CleanupSubDirectoryJob < ApplicationJob
  non_tenant_job

  attr_reader :delete_ingested_after_days, :delete_orphaned_after_days, :directory
  def perform(delete_ingested_after_days:, directory:, delete_orphaned_after_days: 730)
    @directory = directory
    @delete_ingested_after_days = delete_ingested_after_days
    @delete_orphaned_after_days = delete_orphaned_after_days
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

      return true if orphaned_and_old_enough?(path)

      ingested_and_old_enough?(path)
    end

    def ingested_and_old_enough?(path)
      file_older_than?(path, delete_ingested_after_days) && fileset_created?(path)
    end

    def orphaned_and_old_enough?(path)
      file_older_than?(path, delete_orphaned_after_days)
    end

    def file_older_than?(path, days)
      File.mtime(path) < (Time.zone.now - days.to_i.days)
    end

    def fileset_created?(path)
      fs_id = fileset_id(path)
      @files_checked += 1
      Account.find_each do |account|
        begin
          Apartment::Tenant.switch(account.tenant) do
            return true if FileSet.exists?(fs_id)
          end
        rescue StandardError => e
          logger.error("Error checking FileSet #{fs_id} in tenant #{account.tenant}: #{e.message}")
        end
      end

      false
    end

    def fileset_id(path)
      path.split('/')[-2]
    end
end
