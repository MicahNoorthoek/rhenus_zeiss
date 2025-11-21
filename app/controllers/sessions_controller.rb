class SessionsController < ApplicationController
  auto_session_timeout_actions
  require 'os'

  def new
    @indicator = SelectedAuthorization.pluck(:selected_authorization).first
  end

  def create
    begin
      user = User.find_by(username: session_params[:username])
      
      SystemLog.create(procedure_name: 'sessions_controller', log_message: "#{user.username}")
      if user.user_lock
        SystemLog.create(procedure_name: 'sessions_controller', log_message: "why are we here #{user.username}")
        flash[:danger] = "Exceeded login attempts - Please contact support"
        redirect_to login_path and return
      end

      if user&.authenticate(session_params[:password])
        if user.user_lock
          flash[:danger] = "Account is locked. Please contact support."
          tracker.update(successful_login: 'false')
          redirect_to login_path and return
        end

        login_success(user)
        redirect_to dashboard_path
      else
        increment_failed_attempts(user)
        flash[:danger] = "Username or password is invalid"
        redirect_to login_path
      end
    rescue => e
      SystemLog.create(procedure_name: 'sessions_controller', log_message: "Error logging in: #{e.message}")
      flash[:danger] = "Error while attempting to log in"
      redirect_to login_path
    end
  end

  def jstimeout
    logout_user
  end

  def destroy
    logout_user("You have successfully logged out.")
  end

  def on_close
    logout_user
  end

  def active
    render_session_status
  end

  def timeout
    render_session_timeout
  end

  private

  def session_params
    params.require(:session).permit(:username, :password)
  end


  def login_success(user)
    session[:user_id] = user.id
    user.update!(login_attempts: 0, last_sign_in_at: Time.current, logged_in: true)
    session[:last_sign_in] = Time.current

    SystemLog.create(procedure_name: 'sessions_controller', log_message: "User #{user.username} logged in successfully")

    session[:admin_override] = admin_override_path if user.admin?
  end

  def increment_failed_attempts(user)
    if user
      user.increment!(:login_attempts)
      user.update!(user_lock: true) if user.login_attempts >= 3
    end

  end


  def logout_user(message = "You have been logged out due to inactivity.")
    if session[:user_id]
      User.where(id: session[:user_id]).update_all(logged_in: false)
      session.delete(:user_id)
    end
    flash[:info] = message
    redirect_to root_path
  end
end
