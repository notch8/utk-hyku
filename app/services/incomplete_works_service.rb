# frozen_string_literal: true

require 'csv'

# IncompleteWorksService is responsible for generating reports on incomplete works
# in the digital collections. It identifies attachments without filesets, works
# without attachments, and filesets without files, generating CSV files for each report.
#
# Usage:
#   IncompleteWorksService.run_reports
#   IncompleteWorksService.run_reports(reports: [:no_files], rows: 500) # defaults to 100,000 rows
#
# This will create the specified CSV files in the public/uploads directory.
class IncompleteWorksService
  # Run the reports to find incomplete works
  #
  # @return [void]
  #
  # Generates up to 3 CSV files:
  # - attachments_without_filesets.csv: Lists attachments without associated filesets.
  # - works_without_attachments.csv: Lists works that do not have any attachments.
  # - filesets_without_files.csv: Lists filesets that do not have any files.
  def self.run_reports(reports: %i[no_files no_attachments no_filesets], rows: 100_000)
    # Create CSV for attachments without filesets
    if reports.include?(:no_filesets)
      data = no_filesets(rows: rows)
      create_csv(data: data,
                 output_file: 'attachments_without_filesets.csv',
                 headers: ["Attachment URL", "Work Type", "Bulkrax Identifier", "Parent URL"])
      Rails.logger.info "Created attachments_without_filesets.csv in public/uploads"
    end

    # Create CSV for filesets without files
    if reports.include?(:no_files)
      data = no_files(rows: rows)
      create_csv(data: data,
                 output_file: 'filesets_without_files.csv',
                 headers: ["File Set URL", "FileSet Title", "Bulkrax Identifier", "Import URL"])
      Rails.logger.info "Created filesets_without_files.csv in public/uploads"
    end

    return unless reports.include?(:no_attachments)
    # Create CSV for works without attachments
    data = no_attachments(rows: rows)
    create_csv(data: data,
               output_file: 'works_without_attachments.csv',
               headers: ["Work URL", "Work Type", "Bulkrax Identifier"])
    Rails.logger.info "Created works_without_attachments.csv in public/uploads"
  end

  # Find all attachments without members
  def self.no_filesets(rows: 100_000)
    results = Hyrax::SolrService.query(
      "has_model_ssim:Attachment AND -file_set_ids_ssim:[* TO *] AND is_page_of_ssim:[* TO *]",
      rows: rows,
      fl: 'id,is_page_of_ssim,bulkrax_identifier_tesim'
    )
    return [] if results.empty?

    results.map do |hash|
      parent_model = Hyrax::SolrService.query(
        "id:#{hash['is_page_of_ssim'].first}",
        rows: 1
      ).first['has_model_ssim'].first
      parent_id = hash['is_page_of_ssim'].first

      "https://#{Site.account.cname}/concern/parent/#{parent_id}/attachments/#{hash['id']};" \
      "#{parent_model};" \
      "#{hash['bulkrax_identifier_tesim']&.first};" \
      "https://#{Site.account.cname}/concern/#{parent_model.underscore.pluralize}/#{parent_id}"
    end
  end

  def self.no_attachments(rows: 100_000)
    results = []
    (Hyrax.config.curation_concerns - [Attachment]).each do |concern|
      results << Hyrax::SolrService.query(
        "has_model_ssim:#{concern} AND -member_ids_ssim:[* TO *]",
        rows: rows,
        fl: 'id,bulkrax_identifier_tesim,has_model_ssim'
      )
    end

    results.flatten.map do |hash|
      "https://#{Site.account.cname}/concern/#{hash['has_model_ssim'].first.downcase.pluralize}/" \
      "#{hash['id']};" \
      "#{hash['has_model_ssim'].first};" \
      "#{hash['bulkrax_identifier_tesim']&.first}"
    end
  end

  def self.no_files(rows: 100_000)
    results = Hyrax::SolrService.query(
      "has_model_ssim:FileSet AND -file_format_tesim:[* TO *]",
      rows: rows,
      fl: 'id,title_tesim,bulkrax_identifier_tesim,import_url_ssim'
    )
    return [] if results.empty?

    results.map do |hash|
      "https://#{Site.account.cname}/concern/file_sets/#{hash['id']};" \
      "#{hash['title_tesim'].first};" \
      "#{hash['bulkrax_identifier_tesim']&.first};" \
      "#{hash['import_url_ssim']&.first}"
    end
  end

  def self.create_csv(data:, output_file:, headers:)
    # Set file path in public directory
    file_path = Rails.root.join('public', 'uploads', output_file)

    CSV.open(file_path, "wb") do |csv|
      # Add a header row if needed
      csv << headers

      # Process each string in the array
      data.each do |str|
        parts = str.split(';')
        csv << parts
      end
    end
  end
end
