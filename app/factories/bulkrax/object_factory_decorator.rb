# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to use the actor stack for deleting works and file sets.
#   This way when a work gets deleted it will get its attachments and file sets deleted
#   just like if you were deleting it through the UI.
#   @see: Hyrax::Actors::CleanupFileSetsActorDecorator

module Bulkrax
  module ObjectFactoryDecorator
    def delete(user)
      obj = find
      return false unless obj

      if obj.is_a?(Collection)
        super
      elsif obj.is_a?(FileSet)
        return unless Hyrax::Actors::FileSetActor.new(obj, user).destroy
      else
        work_actor = Hyrax::CurationConcern.actor
        attrs = obj.attributes
        env = Hyrax::Actors::Environment.new(obj, Ability.new(user), attrs)

        begin
          return unless work_actor.destroy(env)
        rescue Ldp::Gone
          Rails.logger.warn "Attempted to access deleted resource: #{obj.id}"
          return
        end
      end

      Hyrax.config.callback.run(:after_destroy, obj.id, user, warn: false)
    end
  end
end

Bulkrax::ObjectFactory.prepend(Bulkrax::ObjectFactoryDecorator)
