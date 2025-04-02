# frozen_string_literal: true

class SupplementingContentController < ApplicationController
  def show
    file_set_document = SolrDocument.find(params[:id])
    transcript = file_set_document['transcript_tsimv']&.first
    return render plain: 'No content found', status: :not_found if transcript.blank?

    send_data transcript, type: 'text/vtt', disposition: 'inline'
  end
end
