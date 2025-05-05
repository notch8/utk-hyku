# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to account for UTK filesets not having extensions

module Bulkrax
  module ExportBehaviorDecorator
    def filename(file_set)
      return if file_set.original_file.blank?
      if file_set.original_file.respond_to?(:original_filename) # valkyrie
        fn = file_set.original_file.original_filename
        mime = ::Marcel::MimeType.for(file_set.original_file.file.io)
      else # original non valkyrie version
        fn = file_set.original_file.file_name.first
        mime = ::Marcel::MimeType.for(declared_type: file_set.original_file.mime_type)
      end
      ext_mime = ::Marcel::MimeType.for(name: fn)
      # OVERRIDE begin
      if File.extname(fn).blank?
        filename = "#{file_set.id}_#{fn}" + Rack::Mime::MIME_TYPES.invert[mime]
      elsif fn.include?(file_set.id) || importerexporter.metadata_only?
        # OVERRIDE end
        filename = "#{fn}.#{mime.to_sym}"
        filename = fn if mime.to_s == ext_mime.to_s
      else
        filename = "#{file_set.id}_#{fn}.#{mime.to_sym}"
        filename = "#{file_set.id}_#{fn}" if mime.to_s == ext_mime.to_s
      end
      # Remove extention truncate and reattach
      ext = File.extname(filename)
      "#{File.basename(filename, ext)[0...(220 - ext.length)]}#{ext}"
    end
  end
end

Bulkrax::ExportBehavior.prepend(Bulkrax::ExportBehaviorDecorator)
