# frozen_string_literal: true

# OVERRIDE IiifPrint 1.0.0 to log serialization issues before submitting BatchCreateJob
module IiifPrint
  module Jobs
    module ChildWorksFromPdfJobDecorator
      def split_pdf(original_pdf_path, user, child_model, pdf_file_set)
        image_files = @parent_work.iiif_print_config.pdf_splitter_service.call(original_pdf_path,
                                                                               file_set: pdf_file_set)

        # give as much info as possible if we don't have image files to work with.
        if image_files.blank?
          raise "#{@parent_work.class} (ID=#{@parent_work.id} " /
                "to_param:#{@parent_work.to_param}) " /
                "original_pdf_path #{original_pdf_path.inspect} " /
                "pdf_file_set #{pdf_file_set.inspect}"
        end

        @split_from_pdf_id = pdf_file_set&.id
        prepare_import_data(original_pdf_path, image_files, user)

        # submit the job to create all the child works for one PDF
        # @param [User] user
        # @param [Hash<String => String>] titles
        # @param [Hash<String => String>] resource_types (optional)
        # @param [Array<String>] uploaded_files Hyrax::UploadedFile IDs
        # @param [Hash] attributes attributes to apply to all works, including :model
        # @param [Hyrax::BatchCreateOperation] operation
        operation = Hyrax::BatchCreateOperation.create!(
          user: user,
          operation_type: "PDF Batch Create"
        )

        ## Inspect attributes to find ActiveTriples::Relation errors
        merged_attrs = attributes.merge!(model: child_model.to_s,
                                         split_from_pdf_id: @split_from_pdf_id)
                                 .with_indifferent_access
        # Check for ActiveTriples in attributes
        check_for_active_triples(merged_attrs)
        ## End inspect attributes

        BatchCreateJob.perform_later(user,
                                     @child_work_titles,
                                     {},
                                     @uploaded_files,
                                     merged_attrs,
                                     operation)
      end

      private

        def check_for_active_triples(hash, path = "")
          hash.each do |key, value|
            current_path = path.empty? ? key.to_s : "#{path}.#{key}"
            # rubocop:disable Style/GuardClause
            if value.is_a?(ActiveTriples::Relation)
              raise "Found ActiveTriples::Relation at attributes[#{current_path}]: #{value.inspect}\n
              Value class: #{value.class}\nTo fix: convert to array with .to_a or string with .first"
            elsif value.is_a?(Hash)
              check_for_active_triples(value, current_path)
            elsif value.is_a?(Array)
              value.each_with_index do |item, index|
                if item.is_a?(ActiveTriples::Relation)
                  raise "Found ActiveTriples::Relation at attributes[#{current_path}][#{index}]: #{item.inspect}"
                elsif item.is_a?(Hash)
                  check_for_active_triples(item, "#{current_path}[#{index}]")
                end
              end
            end
            # rubocop:enable Style/GuardClause
          end
        rescue StandardError => e
          error_msg = "ActiveTriples detection: #{e.message}\n
                      \nFull attributes:
                      \n#{JSON.pretty_generate(sanitize_for_json(hash))}"
          # rubocop:disable Style/RaiseArgs
          raise StandardError.new(error_msg)
          # rubocop:enable Style/RaiseArgs
        end

        def sanitize_for_json(obj)
          case obj
          when Hash
            obj.transform_values { |v| sanitize_for_json(v) }
          when Array
            obj.map { |v| sanitize_for_json(v) }
          when ActiveTriples::Relation
            "[ActiveTriples::Relation: #{obj.class.name}]"
          else
            obj.to_s
          end
        end
    end
  end
end

IiifPrint::Jobs::ChildWorksFromPdfJob.prepend(IiifPrint::Jobs::ChildWorksFromPdfJobDecorator)
