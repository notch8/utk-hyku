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
    expect { described_class.perform_now(days_old: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob).exactly(3).times
  end
end
