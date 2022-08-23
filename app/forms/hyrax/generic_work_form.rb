# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  # Generated form for GenericWork
  class GenericWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::GenericWork
    self.terms += [:resource_type]

    include HydraEditor::Form::Permissions
    include AllinsonFlex::DynamicFormBehavior
    include UtkBaseTerms
  end
end
