# frozen_string_literal: true

# OVERRIDE Hyrax 3.5.0 allow downloading directly from S3

require 'aws-sdk-s3'

module Hyrax
  module DownloadsControllerDecorator
    def send_file_contents
      if ENV['S3_DOWNLOADS']
        s3_object = if asset.respond_to?(:s3_only) && asset.s3_only
                      Aws::S3::Object.new(ENV['AWS_BUCKET'], asset.s3_only)
                    else
                      Aws::S3::Object.new(ENV['AWS_BUCKET'], file.digest.first.to_s.gsub('urn:sha1:', ''))
                    end
        if s3_object.exists?
          redirect_to s3_object.presigned_url(
            :get,
            expires_in: 3600,
            response_content_disposition: "attachment\; filename=#{file_name}"
          )
          return
        end
      end

      # If s3 downloads is off, or if the file isn't in s3.
      super
    end

    # Override this if you'd like a different filename
    # @return [String] the filename
    def file_name
      fname = params[:filename] || file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
      fname = CGI.unescape(fname) if Rails.version >= '6.0'
      if File.extname(fname).blank?
        new_ext = MIME::Types[file.mime_type]&.first&.preferred_extension
        fname += '.' + new_ext if new_ext.present?
      end

      fname
    end
  end
end

Hyrax::DownloadsController.prepend(Hyrax::DownloadsControllerDecorator)
