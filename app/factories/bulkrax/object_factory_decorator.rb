# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to use .where instead of .find because UTK uses colons in their
#   bulkrax identifiers which causes issues when using .find

module Bulkrax
  module ObjectFactoryDecorator
    def find(id)
      object = ActiveFedora::Base.where(bulkrax_identifier_tesim: id).first
      return object if object.present?

      super
    end
  end
end

Bulkrax::ObjectFactory.singleton_class.send(:prepend, Bulkrax::ObjectFactoryDecorator)
