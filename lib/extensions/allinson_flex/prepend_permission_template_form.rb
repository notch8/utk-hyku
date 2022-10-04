# frozen_string_literal: true

module AllinsonFlex
  module PrependPermissionTemplateForm
    # override (from Hyrax 2.5.0) - new method to delegate to available_contexts
    delegate :available_contexts, to: :metadata_context_class

    # override (from Hyrax 2.5.0) - new method to setup the metadata_context_class
    def metadata_context_class
      AllinsonFlex::Context
    end

    # override (from Hyrax 2.5.0) - new method to setup dropdown for metadata_context
    def metadata_context_options
      available_contexts.map { |c| [c.name, c.id] }
    end

    # override (from Hyrax 2.5.0) - extend method to add metadata_context
    # @return [Hash{Symbol => String, Boolean}]
    #   {
    #     :content_tab (for confirmation message),
    #     :updated (true/false),
    #     :error_code (for flash error lookup)
    #   }
    def update(attributes)
      @attributes = attributes
      return_info = { content_tab: tab_to_update }
      error_code = nil
      case return_info[:content_tab]
      when 'participants'
        update_participants_options
      when 'visibility'
        error_code = update_visibility_options
      when 'workflow'
        grant_workflow_roles
      when 'metadata_context'
        update_metadata_context
      end
      return_info[:error_code] = error_code if error_code
      return_info[:updated] = error_code ? false : true
      return_info
    end

    private

      # override (from Hyrax 2.5.0) - extend method to add metadata_context
      # @return [String]
      def tab_to_update
        return 'metadata_context' if attributes.key?(:metadata_context_id)

        super
      end

      # override (from Hyrax 2.5.0) - new method to add the admin_set_id to the AllinsonFlex::Context
      # @return [Nil]
      def update_metadata_context
        if attributes['metadata_context_id'].present?
          remove_metadata_context
          metadata_context = AllinsonFlex::Context.find(attributes['metadata_context_id'])
          if metadata_context.admin_set_ids.exclude?(source_model.id)
            metadata_context.admin_set_ids += [source_model.id]
          end
          metadata_context.save
        end
        nil
      end

      # override (from Hyrax 2.5.0) - new method to remove admin_set_id from any other AllinsonFlex::Context
      # Remove the metadata context if this is an update
      def remove_metadata_context
        AllinsonFlex::Context.where.not(admin_set_ids: [nil, []],
                                        id: attributes['metadata_context_id']).each do |cxt|
          cxt.admin_set_ids -= [source_model.id] if cxt.admin_set_ids.include?(source_model.id)
          cxt.save
        end
      end
  end
end
