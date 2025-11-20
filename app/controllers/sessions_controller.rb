class SessionsController < ApplicationController
  auto_session_timeout_actions
  require 'os'

  def new
    @indicator = SelectedAuthorization.pluck(:selected_authorization).first
  end

  def create
    begin
      ip_address = request.remote_ip
      hostname = request.host
      user_agent = request.user_agent.downcase
      used_system = detect_system(user_agent)     

      user = User.find_by(username: session_params[:username])

      if user_locked_or_ip_blocked?(user, ip_address) 
        flash[:danger] = "Exceeded login attempts - Please contact support"
        redirect_to login_path and return
      end

      tracker = log_entrance(session_params[:username], used_system, hostname, ip_address)

      if user&.authenticate(session_params[:password])
        if user.user_lock
          flash[:danger] = "Account is locked. Please contact support."
          tracker.update(successful_login: 'false')
          redirect_to login_path and return
        end

        login_success(user, ip_address)
        tracker.update(successful_login: 'true')
        redirect_to dashboard_path
      else
        increment_failed_attempts(user, ip_address)
        tracker.update(successful_login: 'false')
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

  def detect_system(user_agent)
    return "mobileDevice" if user_agent.match?(/android|iphone/)

    case
    when OS.linux? then "Linux"
    when OS.windows? then "Windows"
    when OS.mac? then "macOS"
    when OS.bsd? then "BSD"
    else "Unqualified OS"
    end
  end

  def log_entrance(username, system, hostname, ip)
    EntranceTracker.create(
      user: username,
      device: system,
      hostname: hostname,
      ip: ip,
      date_logged: Time.zone.now,
      successful_login: '',
      ip_lock: false,
      report: OS.report
    )
  end

  def user_locked_or_ip_blocked?(user, ip_address)
    failed_attempts = EntranceTracker.where(ip: ip_address, successful_login: 'false')
                                     .where('date_logged >= ?', 1.week.ago)
                                     .count

    if failed_attempts > 10
      EntranceTracker.where(ip: ip_address).update_all(ip_lock: true)
      SystemLog.create(procedure_name: 'session_controller', log_message: "IP lock enabled for #{ip_address}")
      return true
    end

    user&.user_lock || EntranceTracker.where(ip: ip_address).order(ip_lock: :desc).pluck(:ip_lock).first
  end

  def login_success(user, ip_address)
    session[:user_id] = user.id
    user.update!(login_attempts: 0, last_sign_in_at: Time.current, logged_in: true)
    session[:last_sign_in] = Time.current

    auth_warehouse = find_user_warehouse(user)
    session[:warehouse] = auth_warehouse

    SystemLog.create(procedure_name: 'sessions_controller', log_message: "User #{user.username} logged in from #{ip_address}, assigned warehouse: #{auth_warehouse}")

    selected_warehouse = Selectedwarehouse.find_or_initialize_by(userid: user.id)
    selected_warehouse.update!(warehouse: auth_warehouse)

    session[:admin_override] = admin_override_path if user.admin?
  end

  def increment_failed_attempts(user, ip_address)
    if user
      user.increment!(:login_attempts)
      user.update!(user_lock: true) if user.login_attempts >= 3
    end

    EntranceTracker.where(ip: ip_address).update_all(ip_lock: true) if EntranceTracker.where(ip: ip_address, successful_login: 'false').count > 10
  end

  def find_user_warehouse(user)
    recent_warehouse = user.recent_warehouse
    return recent_warehouse if recent_warehouse.present?

    warehouse = Useraccess.where(email: user.email).order(warehouse: :desc).pluck(:warehouse).first
    user.update!(recent_warehouse: warehouse) if warehouse
    warehouse || "DefaultWarehouse"
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
