# frozen_string_literal: true

# OVERRIDE: Hyrax v3.6.0 to add truncation support for attribute values in the attribute renderer

module Hyrax
  module Renderers
    module AttributeRendererDecorator
      private

        def li_value(value)
          if options[:truncate] && value.to_s.length > options[:truncate]
            value = ERB::Util.h(value.to_s.truncate(
                                  options[:truncate],
                                  separator: options[:separator] || ' ',
                                  omission: options[:omission] || '...'
            ))
          end

          super(value)
        end
    end
  end
end

Hyrax::Renderers::AttributeRenderer.prepend(Hyrax::Renderers::AttributeRendererDecorator)
