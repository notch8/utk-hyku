# frozen_string_literal: true

RSpec.describe CleanupSubDirectoryJob do
  let(:old_time) { Time.zone.now - 1.year }
  let(:new_time) { Time.zone.now - 1.week }
  let(:path_1) { '/app/samvera/uploads/ff/00/27/d1/file-set-id-1/path_1' }
  let(:path_2) { '/app/samvera/uploads/ff/11/28/19/file-set-id-2/path_2' }
  let(:path_3) { '/app/samvera/uploads/ff/22/17/de/file-set-id-3/path_3' }
  let(:path_4) { '/app/samvera/uploads/ff/33/0d/6b/file-set-id-4/path_4' }
  let(:path_5) { '/app/samvera/uploads/ff/f4/11/30/file-set-id-5/path_5' }
  let(:account_1) { FactoryBot.create(:account) }
  let(:account_2) { FactoryBot.create(:account) }

  before do
    allow(Apartment::Tenant).to receive(:switch).and_call_original
    allow(Apartment::Tenant).to receive(:switch).with(account_1.tenant).and_yield
    allow(Apartment::Tenant).to receive(:switch).with(account_2.tenant).and_return(true)
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/app/samvera/uploads/ff/**/*').and_return([path_5, path_1, path_2,
                                                                                  path_3, path_4])

    allow(Dir).to receive(:empty?).and_return(true)
    allow(FileUtils).to receive(:rmdir)
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:delete)
    allow(File).to receive(:file?).with(path_1).and_return(true)
    allow(File).to receive(:mtime).with(path_1).and_return(old_time)
    allow(File).to receive(:file?).with(path_2).and_return(true)
    allow(File).to receive(:mtime).with(path_2).and_return(old_time)
    allow(File).to receive(:file?).with(path_3).and_return(true)
    allow(File).to receive(:mtime).with(path_3).and_return(new_time)
    allow(File).to receive(:file?).with(path_4).and_return(false)
    allow(File).to receive(:file?).with(path_5).and_return(true)
    allow(File).to receive(:mtime).with(path_5).and_return(old_time)
    allow(FileSet).to receive(:exists?).with('file-set-id-1').and_return(true)
    allow(FileSet).to receive(:exists?).with('file-set-id-2').and_return(true)
    allow(FileSet).to receive(:exists?).with('file-set-id-5').and_return(false)
  end
  it 'deletes files ' do
    expect(File).to receive(:delete).with(path_1)
    expect(File).to receive(:delete).with(path_2)
    # # Too new
    expect(File).not_to receive(:delete).with(path_3)
    # # Not a file
    expect(File).not_to receive(:delete).with(path_4)
    # # Does not have a FileSet yet
    expect(File).not_to receive(:delete).with(path_5)
    # expect(FileSet).to receive(:find).with('file-set-id-5')
    described_class.perform_now(days_old: 180, directory: '/app/samvera/uploads/ff')
  end
  describe 'cleaning up directories' do
    before do
      allow(Dir).to receive(:glob).with("/app/samvera/uploads/ff/*/*/*/*/*")
                                  .and_return([
                                                '/app/samvera/uploads/ff/00/27/d1/file-set-id-1',
                                                '/app/samvera/uploads/ff/11/28/19/file-set-id-2',
                                                '/app/samvera/uploads/ff/22/17/de/file-set-id-3'
                                              ])
      allow(File).to receive(:directory?).and_call_original
      allow(File).to receive(:directory?).with('/app/samvera/uploads/ff/00/27/d1/file-set-id-1').and_return(true)
      allow(File).to receive(:directory?).with('/app/samvera/uploads/ff/11/28/19/file-set-id-2').and_return(true)
      allow(File).to receive(:directory?).with('/app/samvera/uploads/ff/22/17/de/file-set-id-3').and_return(true)
      allow(FileUtils).to receive(:rmdir)
        .with('/app/samvera/uploads/ff/11/28/19/file-set-id-2', parents: true)
        .and_raise(Errno::ENOTEMPTY)
    end

    it 'cleans up empty parent directories' do
      expect(FileUtils).to receive(:rmdir).with('/app/samvera/uploads/ff/00/27/d1/file-set-id-1', parents: true)
      expect(FileUtils).to receive(:rmdir).with('/app/samvera/uploads/ff/11/28/19/file-set-id-2', parents: true)
      expect(FileUtils).to receive(:rmdir).with('/app/samvera/uploads/ff/22/17/de/file-set-id-3', parents: true)

      described_class.perform_now(days_old: 180, directory: '/app/samvera/uploads/ff')
    end
  end
end
