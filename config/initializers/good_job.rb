# frozen_string_literal: true

Rails.application.configure do
  # Configure options individually...
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Raven.capture_exception(exception) }
  config.good_job.execution_mode = :external
  # config.good_job.queues = '*'
  config.good_job.shutdown_timeout = 60 # seconds
  config.good_job.poll_interval = 5
  config.good_job.enable_cron = true
  config.good_job.cron = {
    cleanup_upload_files: {
      cron: '0 2 * * 0',
      class: 'CleanupUploadFilesJob',
      # days_old: delete files with matching FileSets older than this
      # very_old_days: delete orphaned files (no FileSet) older than this
      args: { days_old: 180, uploads_path: '/app/samvera/uploads', very_old_days: 365 },
      enabled_by_default: -> { Rails.env.production? }
    }
  }
end

# Wrapping this in an after_initialize block to ensure that all constants are loaded
Rails.application.config.after_initialize do
  # baseline of 0, higher is sooner

  CreateDerivativesJob.priority = 40
  CharacterizeJob.priority = 30
  Hyrax::GrantEditToMembersJob.priority = 10
  ImportUrlJob.priority = 10
  IngestJob.priority = 10
  ApplicationJob.priority = 0
  AttachFilesToWorkJob.priority = -1
  Bulkrax::ImportWorkJob.priority = -5
  Bulkrax::ImportFileSetJob.priority = -15
  Bulkrax::CreateRelationshipsJob.priority = -20
  Bulkrax::ImporterJob.priority = -20
  IiifPrint::Jobs::CreateRelationshipsJob.priority = -20
  Bulkrax::ScheduleRelationshipsJob.priority = -30
  ContentDepositEventJob.priority = -50
  ContentUpdateEventJob.priority = -50
end
