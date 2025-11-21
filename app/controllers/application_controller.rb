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

end
