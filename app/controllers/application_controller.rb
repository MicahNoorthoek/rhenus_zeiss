class ApplicationController < ActionController::Base
  #allow_browser versions: :modern
  require 'csv'
  require 'date'

  #layout :render_layout
  #protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?
  before_action :agent?
  #auto_session_timeout

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id], logged_in: true) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_user
    unless logged_in?
      flash[:warning] = "You must be logged in to view requested page."
      redirect_to root_path and return
    end

    user = current_user
    user&.update!(user_actions: Time.zone.now)

    selected_warehouse = Selectedwarehouse.find_or_initialize_by(userid: user.id)
    authorized_access = Useraccess.exists?(email: user.email, warehouse: selected_warehouse.warehouse)

    unless authorized_access
      correct_warehouse = Useraccess.where(email: user.email).order(warehouse: :desc).pluck(:warehouse).first
      session[:warehouse] = correct_warehouse

      selected_warehouse.update!(warehouse: correct_warehouse, userid: user.id)
    end
  end

  def authorizedScreens
    selected_warehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
    authorized_screens = UserWarehouseRole.where(warehouse: selected_warehouse, user_email: current_user.email).pluck(:user_tabs)

    permissions = {
      "Receipts" => false,
      "Shipments" => false,
      "Production" => false,
      "Archive" => true # Default to archive being allowed
    }

    authorized_screens.each do |screen|
      permissions[screen] = true if permissions.key?(screen)
    end

    validate_screen_access(permissions)
  end

  def validate_screen_access(permissions)
    if request.path.include?('receipt') && !permissions["Receipts"]
      unauthorized_access("Receipts")
    elsif request.path.include?('withdrawals') && !permissions["Shipments"]
      unauthorized_access("Shipments")
    elsif request.path.include?('production') && !permissions["Production"]
      unauthorized_access("Production")
    elsif request.path.include?('archive') && !permissions["Archive"]
      unauthorized_access("Archive")
    else
      SystemLog.create(procedure_name: 'application', log_message: "User(#{current_user.username}) allowed in current screen: #{request.path}")
    end
  end

  def unauthorized_access(screen)
    SystemLog.create(procedure_name: 'application', log_message: "User(#{current_user.username}) tried accessing unauthorized screen: #{request.path}")
    flash[:danger] = "Unauthorized Action!"
    redirect_to dashboard_path
  end

  def render_layout
    logged_in? && current_user.agent? ? 'agent_application' : 'application'
  end

  def agent?
    if current_user&.agent? && !params[:controller].include?('agent') && !(params[:controller] == "sessions" && params[:action] == 'destroy')
      flash[:danger] = "You are not authorized to access this"
      redirect_to agent_root_path
    end
  end

  def require_admin
    if logged_in? && !current_user.admin?
      flash[:danger] = "Only admin users can perform requested action."
      redirect_to root_path
    end
  end

  def require_user_undo_shipments
    if logged_in? && current_user.undo_shipments_lock?
      flash[:info] = "Corrections are being made by another user. Please wait until completed."
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path }
        format.js { render inline: 'location.replace(location.pathname);' }
      end
    end
  end
end
