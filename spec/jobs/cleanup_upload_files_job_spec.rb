# frozen_string_literal: true

RSpec.describe CleanupUploadFilesJob do
  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/app/samvera/uploads/*').and_return(['path_1', 'path_2', 'path_3', 'path_4'])
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with('path_1').and_return(true)
    allow(File).to receive(:directory?).with('path_2').and_return(true)
    allow(File).to receive(:directory?).with('path_3').and_return(true)
    allow(File).to receive(:directory?).with('path_4').and_return(false)
  end

  it 'spawns child jobs for each sub-directory' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob).exactly(3).times
  end

  it 'passes delete_orphaned_after_days parameter to child jobs' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180,
                                  uploads_path: '/app/samvera/uploads',
                                  delete_orphaned_after_days: 365)
    end.to have_enqueued_job(CleanupSubDirectoryJob)
      .with(delete_ingested_after_days: 180, directory: 'path_1', delete_orphaned_after_days: 365)
  end

  it 'uses default delete_orphaned_after_days of 730 when not specified' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob)
      .with(delete_ingested_after_days: 180, directory: 'path_1', delete_orphaned_after_days: 730)
  end
end
