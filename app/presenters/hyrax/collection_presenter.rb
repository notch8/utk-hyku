# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.1: add collection methods to collection presenter and
#    override to return full banner_file data, rather than only download path to file
# Terms is the list of fields displayed by app/views/collections/_show_descriptions.html.erb
# rubocop:disable Metrics/BlockLength
require_dependency Hyrax::Engine.root.join('app', 'presenters', 'hyrax', 'collection_presenter').to_s

Hyrax::CollectionPresenter.class_eval do
  # OVERRIDE Hyrax - removed size
  delegate :abstract, :date_created_d, :date_issued, :date_issued_d,
           :extent, :form, :primary_identifier, :publication_place, :repository, :resource_link,
           :note, :spatial, :utk_contributor, :utk_creator, :utk_publisher,
           to: :solr_document

  def self.terms
    %i[ total_items
        abstract
        contributor
        creator
        date_created
        date_created_d
        date_issued
        date_issued_d
        extent
        form
        keyword
        note
        publication_place
        publisher
        primary_identifier
        repository
        resource_link
        resource_type
        spatial
        subject
        utk_contributor
        utk_creator
        utk_publisher ]
  end

  def [](key)
    case key
    when :total_items
      total_items
    else
      solr_document.send key
    end
  end

  # override to hide empty fields
  def terms_with_values
    self.class.terms.select do |t|
      value = send(t).try(:first)
      # total_items is always displayed
      t == :total_items || value.present?
    end
  end

  # override banner_file in hyrax to include all banner information rather than just relative_path
  def banner_file
    @banner_file ||= begin
      # Find Banner filename
      banner_info = CollectionBrandingInfo.where(collection_id: id, role: "banner")
      filename = File.split(banner_info.first.local_path).last unless banner_info.empty?
      alttext = banner_info.first.alt_text unless banner_info.empty?
      relative_path = "/" + banner_info.first.local_path.split("/")[-4..-1].join("/") unless banner_info.empty?
      { filename: filename, relative_path: relative_path, alt_text: alttext }
    end
  end

  # Begin Featured Collections Methods
  def collection_featurable?
    user_can_feature_collection? && solr_document.public?
  end

  def display_feature_collection_link?
    collection_featurable? && FeaturedCollection.can_create_another? && !collection_featured?
  end

  def display_unfeature_collection_link?
    collection_featurable? && collection_featured?
  end

  def collection_featured?
    # only look this up if it's not boolean; ||= won't work here
    if @collection_featured.nil?
      @collection_featured = FeaturedCollection.where(collection_id: solr_document.id).exists?
    end
    @collection_featured
  end

  def user_can_feature_collection?
    current_ability.can?(:create, FeaturedCollection)
  end
  # End Featured Collections Methods
end
# rubocop:enable Metrics/BlockLength
