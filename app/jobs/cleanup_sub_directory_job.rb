# frozen_string_literal: true

class CleanupSubDirectoryJob < ApplicationJob
  attr_reader :days_old, :directory
  def perform(days_old:, directory:)
    @directory = directory
    @days_old = days_old
    delete_files
  end

  private

    def delete_files
      Dir.glob("#{directory}/**/*").each do |path|
        next unless should_be_deleted?(path)

        File.delete(path)
        FileUtils.rmdir(parent_directory(path), parents: true) if Dir.empty?(parent_directory(path))
      end
    end

    def should_be_deleted?(path)
      File.file?(path) && ((old_enough(path) && fileset_created?(path)) || very_old?(path))
    end

    def old_enough(path)
      return true if File.mtime(path) < (Time.zone.now - days_old.to_i.days)

      false
    end

    def very_old?(path)
      return true if File.mtime(path) < (Time.zone.now - 2.years)

      false
    end

    def parent_directory(path)
      split_path = path.split('/')
      split_path[0..-2].join('/')
    end

    def fileset_created?(path)
      fs_id = path.split('/')[-2]
      file_set = FileSet.find(fs_id)
      return true if file_set&.original_file&.present?

      false
    rescue ActiveFedora::ObjectNotFoundError
      false
    end
end
