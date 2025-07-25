# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability
  include AllinsonFlex::Ability

  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
    featured_collection_abilities
  ]

  # Define any customized permissions here.
  def custom_permissions
    can [:create], Account
  end

  def admin_permissions
    return unless admin?
    return if superadmin?

    super
    can [:manage], [Site, Role, User]

    can [:read, :update], Account do |account|
      account == Site.account
    end
  end

  def group_permissions
    return unless admin?

    can :manage, Hyku::Group
  end

  def superadmin_permissions
    return unless superadmin?

    can :manage, :all
  end

  def superadmin?
    current_user.has_role? :superadmin
  end

  def featured_collection_abilities
    can %i[create destroy update], FeaturedCollection if admin?
  end

  # Override from blacklight-access_controls-0.6.2 to define registered to include having a role on this tenant
  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    @user_groups |= current_user.groups if current_user.respond_to? :groups
    @user_groups |= ['registered'] if !current_user.new_record? && current_user.roles.count.positive?
    @user_groups
  end

  def can_import_works?
    can_create_any_work?
  end

  def can_export_works?
    can_create_any_work?
  end

  ##
  # @api public
  #
  # Overrides hydra-head to allow collection_viewer to view everything in a collection
  def test_download(id)
    current_user.collection_viewer?(id) || super
  end

  def test_read(id)
    current_user.collection_viewer?(id) || super
  end
end
