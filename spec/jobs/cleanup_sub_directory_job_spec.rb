# frozen_string_literal: true

RSpec.describe CleanupSubDirectoryJob do
  let(:old_time) { Time.zone.now - 1.year }
  let(:new_time) { Time.zone.now - 1.week }
  let(:fs_double) { instance_double(FileSet, original_file: true) }
  let(:path_1) { '/app/samvera/uploads/ff/00/27/d1/file-set-id-1/path_1' }
  let(:path_2) { '/app/samvera/uploads/ff/11/28/19/file-set-id-2/path_2' }
  let(:path_3) { '/app/samvera/uploads/ff/22/17/de/file-set-id-3/path_3' }
  let(:path_4) { '/app/samvera/uploads/ff/33/0d/6b/file-set-id-4/path_4' }
  let(:path_5) { '/app/samvera/uploads/ff/f4/11/30/file-set-id-5/path_5' }

  before do
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
    allow(FileSet).to receive(:find).with('file-set-id-1').and_return(fs_double)
    allow(FileSet).to receive(:find).with('file-set-id-2').and_return(fs_double)
    allow(FileSet).to receive(:find).with('file-set-id-5').and_raise(ActiveFedora::ObjectNotFoundError)
  end
  it 'deletes files ' do
    expect(File).to receive(:delete).with(path_1)
    expect(File).to receive(:delete).with(path_2)
    # Too new
    expect(File).not_to receive(:delete).with(path_3)
    # Not a file
    expect(File).not_to receive(:delete).with(path_4)
    # Does not have a FileSet yet
    expect(File).not_to receive(:delete).with(path_5)
    expect(FileSet).to receive(:find).with('file-set-id-5')
    described_class.perform_now(days_old: 180, directory: '/app/samvera/uploads/ff')
  end

  it 'cleans up empty parent directories' do
    expect(Dir).to receive(:empty?).with('/app/samvera/uploads/ff/00/27/d1/file-set-id-1')
    expect(Dir).to receive(:empty?).with('/app/samvera/uploads/ff/11/28/19/file-set-id-2')

    # expect(FileUtils).to receive(:rmdir).with('/app/samvera/uploads/ff/00/27/d1/file-set-id-1')
    described_class.perform_now(days_old: 180, directory: '/app/samvera/uploads/ff')
  end
end
