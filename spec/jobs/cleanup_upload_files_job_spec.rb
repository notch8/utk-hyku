# frozen_string_literal: true

RSpec.describe CleanupUploadFilesJob do
  let(:hex_dir_ff) { '/app/samvera/uploads/ff' }
  let(:hex_dir_00) { '/app/samvera/uploads/00' }
  let(:hex_dir_ab) { '/app/samvera/uploads/ab' }
  let(:uuid_tenant_dir) { '/app/samvera/uploads/56e0eb81-c2d5-4d5d-9171-b251bf7299a4' }

  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/app/samvera/uploads/*')
      .and_return([hex_dir_ff, hex_dir_00, hex_dir_ab, uuid_tenant_dir, '/app/samvera/uploads/somefile'])
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with(hex_dir_ff).and_return(true)
    allow(File).to receive(:directory?).with(hex_dir_00).and_return(true)
    allow(File).to receive(:directory?).with(hex_dir_ab).and_return(true)
    allow(File).to receive(:directory?).with(uuid_tenant_dir).and_return(true)
    allow(File).to receive(:directory?).with('/app/samvera/uploads/somefile').and_return(false)
  end

  it 'spawns child jobs only for hex pair-tree directories (not tenant UUID dirs)' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob).exactly(3).times
  end

  it 'does not create CleanupSubDirectoryJob for tenant UUID directories' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads')
    end.not_to have_enqueued_job(CleanupSubDirectoryJob).with(directory: uuid_tenant_dir)
  end

  it 'passes delete_all_after_days and uploads_path to child jobs' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180,
                                  uploads_path: '/app/samvera/uploads',
                                  delete_all_after_days: 365)
    end.to have_enqueued_job(CleanupSubDirectoryJob)
      .with(delete_ingested_after_days: 180, directory: hex_dir_ff, uploads_path: '/app/samvera/uploads', delete_all_after_days: 365)
  end

  it 'uses default delete_all_after_days of 730 when not specified' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob)
      .with(delete_ingested_after_days: 180, directory: hex_dir_ff, uploads_path: '/app/samvera/uploads', delete_all_after_days: 730)
  end
end
