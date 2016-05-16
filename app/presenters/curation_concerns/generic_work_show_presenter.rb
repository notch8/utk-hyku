class CurationConcerns::GenericWorkShowPresenter < Sufia::WorkShowPresenter
  def manifest_url
    manifest_helper.polymorphic_url([:manifest, self])
  end

  private

    def manifest_helper
      @manifest_helper ||= IIIFManifest::ManifestHelper.new
    end
end
