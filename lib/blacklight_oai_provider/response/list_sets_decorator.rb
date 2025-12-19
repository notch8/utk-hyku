# frozen_string_literal: true

# Override BlacklightOaiProvider v6.1.1 to customize setSpec and setName for collections
module BlacklightOaiProvider
  module Response
    module ListSetsDecorator
      def initialize(*args)
        super
        sets = provider.model.sets
        return unless sets
        @lookup = initialize_set_info_for(sets)
      end

      def to_xml
        raise OAI::SetException unless provider.model.sets

        response do |r|
          r.ListSets do
            provider.model.sets.each do |set|
              r.set do

                r.setSpec set.spec
                r.setName collection_name_for(set)

                if set.respond_to?(:description) && set.description
                  r.setDescription do
                    r.tag!("#{oai_dc.prefix}:#{oai_dc.element_namespace}", oai_dc.header_specification) do
                      r.dc :description, set.description
                    end
                  end
                end
              end
            end
          end
        end
      end

      private

      def initialize_set_info_for(sets)
        ids = sets.map(&:value)
        hits = Hyrax::SolrService.query("id:(#{ids.join(' OR ')})", rows: ids.size, fl: 'id,primary_identifier_tesim,title_tesim')
        hits.each_with_object({}) do |hit, hash|
          hash[hit['id']] = hit
        end
      end

      def collection_name_for(set)
        name = @lookup.dig(set.value,'title_tesim')&.first
        return set.spec unless name.present?
        "#{set.label.titleize}: #{name}"
      end
    end
  end
end

BlacklightOaiProvider::Response::ListSets.prepend(BlacklightOaiProvider::Response::ListSetsDecorator)
