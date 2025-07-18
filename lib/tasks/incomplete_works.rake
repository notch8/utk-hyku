# frozen_string_literal: true

namespace :hyku do
  desc "Create no_files or no_attachments incomplete work reports"
  task :incomplete_works, %i[tenant reports rows] => :environment do |_t, args|
    begin
      tenant = args[:tenant]

      # Validate that tenant is provided
      if tenant.blank?
        puts "ERROR: Account tenant name must be provided as an argument"
        puts "Examples:"
        puts "  rake hyku:incomplete_works[tenant]                  # Run all reports with default row limit of 100,000"
        puts "  rake hyku:incomplete_works[tenant,no_files]         # Run only no_files report"
        puts "  rake hyku:incomplete_works[tenant,no_filesets]      # Run only no_filesets report"
        puts "  rake hyku:incomplete_works[tenant,no_attachments]   # Run only no_attachments report"
        puts "  rake hyku:incomplete_works[tenant,no_files,500]     # Run no_files report with 500 row limit"
        puts "  rake hyku:incomplete_works[tenant,,500]             # Run all reports, each with 500 row limit"
        exit(1)
      end

      # Validate report types
      valid_reports = %i[no_attachments no_filesets no_files]
      reports = args[:reports] ? args[:reports].split(',').map(&:to_sym) : valid_reports
      invalid_reports = reports - valid_reports

      if invalid_reports.any?
        puts "ERROR: Invalid report type(s): #{invalid_reports.join(', ')}"
        puts "Valid report types are: #{valid_reports.join(', ')}"
        exit(1)
      end

      # Validate row limit is a positive integer
      rows = if args[:rows].present?
               if args[:rows].match?(/\A\d+\z/) && args[:rows].to_i.positive?
                 args[:rows].to_i
               else
                 puts "ERROR: Row limit must be a positive integer if provided."
                 puts "You provided: '#{args[:rows]}'"
                 exit(1)
               end
             else
               100_000 # Default row limit
             end

      # Validate that tenant exists
      account = Account.find_by(name: tenant)
      if account.nil?
        puts "ERROR: Account with name '#{tenant}' not found."
        puts "Please ensure the tenant name is correct and the account exists."
        exit(1)
      end

      switch!(account)
      IncompleteWorksService.run_reports(reports: reports, rows: rows)

      puts "Reports generated successfully in public/uploads directory."
      puts "Check the following files:"
      reports.each do |report|
        case report
        when :no_files
          puts "  /uploads/filesets_without_files.csv"
        when :no_filesets
          puts "  /uploads/attachments_without_filesets.csv"
        when :no_attachments
          puts "  /uploads/works_without_attachments.csv"
        end
      end
    rescue StandardError => e
      puts "ERROR: An error occurred while generating reports:"
      puts e.message
      puts e.backtrace[0..5].join("\n") # Show first 6 lines of backtrace
      exit(1)
    end
  end
end
