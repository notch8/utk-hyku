# frozen_string_literal: true

class StatusController < ApplicationController
  layout 'hyrax/dashboard'

  before_action do
    authorize! :read, :admin_dashboard
  end

  def show
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.system_status'), main_app.status_path
  end

  def update
    @endpoint = Endpoint.find(params[:id])
    result = %x{@endpoint.restart_command} if @endpoint.restart_command.present? && @endpoint.last_restart < 5.minutes.ago
    @endpoint.update(last_restart: Time.now)
    flash[:notice] = "Restart result was: #{result}"
    redirect_to status_path
  end
end
