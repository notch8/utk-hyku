# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UriCache, type: :model do
  it 'validates presence of uri' do
    expect(build(:uri_cache, uri: nil)).not_to be_valid
    expect(build(:uri_cache, uri: '')).not_to be_valid
  end

  it 'validates uniqueness of uri' do
    allow(UriToStringConverterService).to receive(:uri_to_value_for).and_return('some value')

    existing_cache = create(:uri_cache, uri: 'http://example.com')
    new_cache = build(:uri_cache, uri: existing_cache.uri)

    expect(new_cache).not_to be_valid
    expect(new_cache.errors[:uri]).to include('has already been taken')
  end

  it 'validates presence of value' do
    expect(build(:uri_cache, value: nil)).not_to be_valid
    expect(build(:uri_cache, value: '')).not_to be_valid
  end

  describe '#update_cache' do
    let(:uri) { 'http://example.com/resource' }
    let(:cache) { create(:uri_cache, uri: uri) }

    before do
      allow(UriToStringConverterService).to(
        receive(:uri_to_value_for).with(uri, fetch_from_remote: true).and_return('updated value')
      )
    end

    it 'updates the value from the service' do
      expect { cache.update_cache }.to change { cache.reload.value }.to('updated value')
    end
  end

  describe '.update_all_caches!' do
    before do
      allow(UriToStringConverterService).to receive(:uri_to_value_for).and_return('updated value')
    end

    it 'updates all caches' do
      cache1 = create(:uri_cache, uri: 'http://example.com/1', value: 'old value 1')
      cache2 = create(:uri_cache, uri: 'http://example.com/2', value: 'old value 2')

      expect do
        UriCache.update_all_caches!
      end.to change { cache1.reload.value }.to('updated value').and change { cache2.reload.value }.to('updated value')
    end
  end

  describe '.create' do
    context 'when both uri and value are provided' do
      it 'creates a new cache entry' do
        uri = 'http://example.com/resource'
        value = 'some value'
        cache = UriCache.create(uri: uri, value: value)

        expect(cache).to be_persisted
        expect(cache.uri).to eq(uri)
        expect(cache.value).to eq(value)
      end
    end

    context 'when only uri is provided' do
      let(:uri) { 'http://example.com/resource' }

      before do
        allow(UriToStringConverterService).to receive(:uri_to_value_for).with(uri).and_return('fetched value')
      end

      it 'fetches the value and creates a new cache entry' do
        cache = UriCache.create(uri: uri)

        expect(cache).to be_persisted
        expect(cache.uri).to eq(uri)
        expect(cache.value).to eq('fetched value')
      end

      it 'raises an error if the fetched value includes the uri' do
        allow(UriToStringConverterService).to receive(:uri_to_value_for).with(uri).and_return(uri)

        expect { UriCache.create(uri: uri) }.to raise_error(StandardError, uri)
      end
    end
  end
end
