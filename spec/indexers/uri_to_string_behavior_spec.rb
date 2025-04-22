# frozen_string_literal: true

RSpec.describe UriToStringBehavior do
  subject { AppIndexer.new(work) }

  let(:work) { double('work') }
  let(:graph) { RDF::Graph.new }
  let(:uri) { 'http://test.uri' }

  describe '#uri_to_value_for' do
    context 'when the URI is an RDF resource' do
      let(:modified_uri) { subject.send(:extract_rdf_components, uri).first }

      before do
        reader_format =
          if rdf_data.end_with?('.nt')
            :ntriples
          elsif rdf_data.end_with?('.rdf')
            :rdfxml
          elsif rdf_data.end_with?('.ttl')
            :ttl
          else
            raise 'Unsupported file format'
          end

        File.open(rdf_data, 'r') do |file|
          RDF::Reader.for(reader_format).new(file) do |reader|
            reader.each_statement { |statement| graph << statement }
          end
        end

        allow(RDF::Graph).to(
          receive(:load).with(modified_uri, headers: { 'Accept' => 'application/rdf+xml' }).and_return(graph)
        )
      end

      context 'from the Library of Congress' do
        let(:uri) { 'https://id.loc.gov/authorities/names/n79007751' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'loc.nt').to_s }

        it 'retrieves a value for a given URI' do
          expect(subject.uri_to_value_for(uri)).to eq 'New York (N.Y.)'
        end
      end

      context 'from the Getty' do
        let(:uri) { 'http://vocab.getty.edu/page/aat/300022208' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'getty.nt').to_s }

        it 'retrieves a value for a given URI' do
          expect(subject.uri_to_value_for(uri)).to eq 'Postmodern'
        end
      end

      context 'from Geonames' do
        let(:uri) { 'http://sws.geonames.org/4624443' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'geonames.rdf').to_s }

        it 'retrieves a value for a given URI' do
          expect(subject.uri_to_value_for(uri)).to eq 'Gatlinburg'
        end
      end

      context 'from WikiData' do
        let(:uri) { 'https://www.wikidata.org/entity/Q85304029' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'wikidata.nt').to_s }

        it 'retrieves a value for a given URI' do
          expect(subject.uri_to_value_for(uri)).to eq 'Dorothy Doolittle'
        end
      end

      context 'from Homosaurus' do
        let(:uri) { 'https://homosaurus.org/v3/homoit0000070' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'homosaurus.nt').to_s }

        it 'retrieves a value for a given URI' do
          expect(subject.uri_to_value_for(uri)).to eq 'LGBTQ+ artists'
        end
      end

      # rubocop:disable RSpec/NestedGroups
      context 'when the URI is a Rights Statement' do
        let(:uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'rights.ttl').to_s }

        context 'from QA' do
          it 'retrieves a value for a given URI' do
            expect(subject.uri_to_value_for(uri)).to eq 'In Copyright'
          end
        end

        context 'from remote' do
          it 'retrieves a value for a given URI' do
            authority = instance_double(Qa::Authorities::Local::FileBasedAuthority)
            allow(Qa::Authorities::Local).to receive(:subauthority_for).with('rights_statements').and_return(authority)
            allow(authority).to receive(:find).with(uri).and_return(term: nil)

            expect(subject.uri_to_value_for(uri)).to eq 'In Copyright'
          end
        end
      end

      context 'when the URI is a License' do
        let(:uri) { 'http://creativecommons.org/licenses/by-nc/4.0/' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'licenses.rdf').to_s }

        context 'from QA' do
          it 'retrieves a value for a given URI' do
            expect(subject.uri_to_value_for(uri)).to include 'Attribution-NonCommercial 4.0 International'
          end
        end

        context 'from remote' do
          it 'retrieves a value for a given URI' do
            authority = instance_double(Qa::Authorities::Local::FileBasedAuthority)
            allow(Qa::Authorities::Local).to receive(:subauthority_for).with('licenses').and_return(authority)
            allow(authority).to receive(:find).with(uri).and_return(term: nil)

            expect(subject.uri_to_value_for(uri)).to include 'Attribution-NonCommercial 4.0 International'
          end
        end
      end

      context 'UriCache' do
        let(:uri) { 'http://id.loc.gov/authorities/names/n2017180154' }
        let(:rdf_data) { Rails.root.join('spec', 'fixtures', 'rdf_data', 'loc_ut.nt').to_s }

        context 'when the URI is cached' do
          before { create(:uri_cache) }

          it 'pulls from the cache' do
            expect(subject.uri_to_value_for('http://id.loc.gov/authorities/names/n2017180154'))
              .to eq 'University of Tennessee'
          end
        end

        context 'when the URI is not cached' do
          it 'caches the URI' do
            expect { subject.uri_to_value_for(uri) }.to change { UriCache.where(uri: uri).count }.from(0).to(1)
            expect(UriCache.find_by(uri: uri).value).to eq 'University of Tennessee'
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when the URI is just a string' do
      it 'returns the value' do
        expect(subject.uri_to_value_for('Doe, John')).to eq 'Doe, John'
      end
    end

    context 'when the URI is not an RDF resource' do
      before do
        allow(RDF::Graph).to(
          receive(:load)
            .with(uri, headers: { 'Accept' => 'application/rdf+xml' })
            .and_raise(StandardError, 'Test error')
        )
      end

      it 'returns the URI and a message' do
        expect(Rails.logger).to receive(:error).with('Failed to load RDF data: Test error')
        expect(subject.uri_to_value_for(uri))
          .to eq 'http://test.uri (Failed to load URI)'
      end
    end

    context 'when the URI does not have a label', skip: 'currently failing in CI but not locally' do
      before do
        stub_request(:get, "http://example.com/")
          .with(
            # rubocop:disable Metrics/LineLength
            headers: {
              'Accept' => 'text/turtle, text/rdf+turtle, application/turtle;q=0.2, application/x-turtle;q=0.2, application/ld+json, application/x-ld+json, application/n-triples, text/plain;q=0.2, application/rdf+xml, application/n-quads, text/x-nquads;q=0.2, */*;q=0.1',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent' => 'Ruby RDF.rb/3.1.15'
            }
            # rubocop:enable Metrics/LineLength
          )
          .to_return(status: 200, body: "", headers: {})
      end
      it 'returns the URI and a message' do
        expect(subject.uri_to_value_for('http://example.com')).to eq 'http://example.com (No label found)'
      end
    end
  end
end
