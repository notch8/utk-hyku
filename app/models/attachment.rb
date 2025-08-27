# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Attachment`
class Attachment < ActiveFedora::Base
  include SharedWorkBehavior
  include IiifPrint.model_configuration

  after_update :update_file_set_visibility

  self.indexer = AttachmentIndexer

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []

  # A utility method for determining if a given Attachment is an intermediate file.
  def intermediate_file?
    return false if rdf_type.blank?

    Hyrax::ConditionalDerivativeDecorator.intermediate_file?(object: self)
  end

  # If we update the Attachment's visibility, we should also update the FileSet's visibility
  def update_file_set_visibility
    file_sets.each do |fs|
      next if visibility == fs.visibility

      fs.update!(visibility: visibility)
    end
  end
end
