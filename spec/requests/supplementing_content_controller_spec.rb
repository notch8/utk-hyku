# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SupplementingContentController, type: :controller do
  let(:file_set_id) { 'some_file_set_id' }
  let(:file_set_doc) { SolrDocument.new(id: file_set_id, transcript_tsimv: [transcript]) }
  let(:transcript) { "WEBVTT\n\n00:00:01.000 --> 00:00:05.000\nThis is a test VTT" }

  before do
    allow(SolrDocument).to receive(:find).with(file_set_id).and_return(file_set_doc)
  end

  describe 'GET #show' do
    context 'when the file set has a transcript' do
      it 'returns a success response' do
        get :show, params: { id: 'some_file_set_id' }
        expect(response).to be_successful
        expect(response.content_type).to eq('text/vtt')
        expect(response.body).to eq(transcript)
        expect(response.headers['Content-Disposition']).to include('inline')
      end
    end

    context 'when there is no digest' do
      let(:transcript) { [] }

      it "returns not found status" do
        get :show, params: { id: 'some_file_set_id' }
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq('No content found')
      end
    end
  end
end
