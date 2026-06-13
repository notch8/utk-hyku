# frozen_string_literal: true

namespace :tenants do
  desc "Calculate total file usage per tenant"
  task calculate_usage: :environment do
    results = []

    Account.where(search_only: false).find_each do |account|
      next if account.cname.blank?

      begin
        AccountElevator.switch!(account.cname)
        puts "---------------#{account.cname}-------------------------"

        models = Hyrax.config.curation_concerns.map { |m| %("#{m}") }
        query = "has_model_ssim:(#{models.join(' OR ')})"

        rows = ENV.fetch("ROWS", 100).to_i
        start = 0
        work_count = 0
        total_bytes = 0

        loop do
          works = ActiveFedora::SolrService.query(
            query,
            rows: rows,
            start: start,
            fl: "id,file_set_ids_ssim"
          )

          break if works.blank?

          work_count += works.length

          file_ids = works.flat_map { |work| Array(work["file_set_ids_ssim"]) }
                          .compact
                          .uniq

          file_ids.each_slice(rows) do |batch|
            file_query = "id:(#{batch.map { |id| %("#{id}") }.join(' OR ')})"

            files = ActiveFedora::SolrService.query(
              file_query,
              rows: batch.size,
              fl: "id,file_size_lts"
            )

            total_bytes += files.sum { |file| file["file_size_lts"].to_i }
          end

          puts "#{account.cname}: checked #{work_count} works, #{(total_bytes / 1.0.megabyte).round(2)} MB so far"

          start += rows
        end

        total_mb = (total_bytes / 1.0.megabyte).round(2)
        results << "#{account.cname}: #{total_mb} Total MB / #{work_count} Works"

        puts results.last
        puts "=================================================================="
      rescue StandardError => e
        results << "#{account.cname}: ERROR - #{e.class}: #{e.message}"
        warn results.last
        next
      end
    end

    puts "\nFinal results:"
    results.each { |result| puts result }
  end
end