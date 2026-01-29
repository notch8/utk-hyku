# frozen_string_literal: true

class CleanupSubDirectoryJob < ApplicationJob
  attr_reader :days_old, :directory
  def perform(days_old:, directory:)
    @directory = directory
    @days_old = days_old
    delete_files
    delete_empty_directories
  end

  private

    def delete_files
      Dir.glob("#{directory}/**/*").each do |path|
        next unless should_be_deleted?(path)

        File.delete(path)
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

      Rails.logger.info("Completed empty directory cleanup for #{directory}")
    end

    def should_be_deleted?(path)
      return false unless File.file?(path)

      return true if very_old?(path)

      old_enough?(path) && fileset_created?(path)
    end

    def old_enough?(path)
      File.mtime(path) < (Time.zone.now - days_old.to_i.days)
    end

    def very_old?(path)
      File.mtime(path) < (Time.zone.now - 2.years)
    end

    def fileset_created?(path)
      fs_id = fileset_id(path)

      Account.find_each do |account|
        begin
          account.switch do
            return true if FileSet.exists?(fs_id)
          end
        rescue StandardError => e
          Rails.logger.error("Error checking FileSet #{fs_id} in tenant #{account.tenant}: #{e.message}")
        end
      end

      false
    end

    def fileset_id(path)
      path.split('/')[-2]
    end
end
