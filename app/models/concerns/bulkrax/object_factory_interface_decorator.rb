# frozen_string_literal: true

# OVERRIDE to account for added Attachment model connecting works to FileSets
module Bulkrax
  module ObjectFactoryInterfaceDecorator
    def update
      raise "Object doesn't exist" unless object
      conditionally_destroy_existing_files

      attrs = transform_attributes(update: true)
      run_callbacks :save do
        if klass == Bulkrax.collection_model_class
          update_collection(attrs)
        elsif klass == Bulkrax.file_model_class
          update_file_set(attrs)
        elsif klass == Attachment
          update_attachment(attrs)
        else
          update_work(attrs)
        end
      end
      apply_depositor_metadata
      log_updated(object)
    end

    def update_attachment(attrs)
      work_actor.update(environment(attrs))

      object.file_sets.each do |fs|
        file_set_attrs = attrs.slice(*fs.attributes.keys)
        actor = Hyrax::Actors::FileSetOrderedMembersActor.new(fs, @user)
        actor.attach_to_work(object, file_set_attrs)
      end
    end
  end
end

Bulkrax::ObjectFactoryInterface.prepend(Bulkrax::ObjectFactoryInterfaceDecorator)
