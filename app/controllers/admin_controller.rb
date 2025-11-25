class AdminController < ApplicationController
  before_action :require_user
  #before_action :last_sign_in
  before_action :require_admin

  def index

  end

  def authorize_user

    curauth = SelectedAuthorization.pluck(:selected_authorization)

    if curauth == [false]
      SelectedAuthorization.update(:selected_authorization => 'true')
      flash[:success] = "New Users can now be created."
      #UserTimerWorker.perform_in(15.minutes)
    else
      SelectedAuthorization.update(:selected_authorization => 'false')

      flash[:success] = "New Users can no longer be created."
    end
    redirect_to manage_users_redirect_path


  end

  def smplbw_users
    load_manage_users_context
  end

  def zeiss_users
    load_manage_users_context
  end

  def receipt_headers_view
    @receiptheader = SpcReceipt.all
    @rh = @receiptheader.ransack(params[:receipt_headers])
    @receipt_headers =  @rh.result.order('releasedate desc').paginate(page: params[:receipt_headers_page], per_page: 10)
  end

  def withdrawals_headers_view
    @withdrawal_headers = SpcShipment.all
    @wh = @withdrawal_headers.ransack(params[:withdrawal_headers])
    @withdrawal_headers =  @wh.result.order('releasedate desc').paginate(page: params[:withdrawal_headers_page], per_page: 10)
  end

  def balances_view
    @rd = Reviewdiscrepancies.ransack(params[:reviewdiscrepancies], search_key: :reviewdiscrepancies)
    @reviewdiscrepancies = @rd.result.order(balancedate: :desc).paginate(page: params[:reviewdiscrepancies_page], per_page: 20)
  end

  def system_log
    @systembase = SystemLog.all
    @s = @systembase.ransack(params[:system_logs])
    @system_logs =  @s.result.order('log_date desc').paginate(page: params[:system_logs_page], per_page: 10)
  end

  def all_receipt_view
    @r = Warehousereceipt.ransack(params[:receipts], search_key: :receipts)
    @receipts = @r.result.paginate(page: params[:receipts_page], per_page: 20)
  end

  def all_withdrawals_view
    @withdrawal_headers = Sp.all
    @w = @withdrawal_headers.ransack(params[:withdrawals], search_key: :withdrawals)
    @withdrawals =  @w.result.order('createdate desc').paginate(page: params[:withdrawals_page], per_page: 20)
  end

  def client_setup
    @form300referencedata = Form300referencedata.all.order(firmscode: :desc)
    @partnumbers = Partnumber.all
    @uomconversion = Uomconversion.all
    @warehousesetup = Warehousesetup.all
  end

  def authorization
    @u = User.ransack(params[:users])
    @users = @u.result.paginate(page: params[:users_page], per_page: 10)

    @verifiedusers = VerifiedUser.new
    @authusr = SelectedAuthorization.all
    @currentusers = VerifiedUser.select(:email).order(email: :asc)
    @selectedemail = SelectedEmail.new
    @restpasswordusers = User.select(:email).order(email: :asc)
  end


  def verify_user
    @verifiedusers = VerifiedUser.new
    @currentusers = VerifiedUser.select(:email).order(email: :asc)

    render partial: "admin/verify_user"  
  end


  def forgot_password
    @u = User.ransack(params[:users])
    @users = @u.result.paginate(page: params[:users_page], per_page: 10)

    @authusr = SelectedAuthorization.all
    @selectedemail = SelectedEmail.new
    @restpasswordusers = User.select(:email).order(email: :asc)
  end


  def smplbw_firmscode_setup
    #control_email = Useraccess.pluck(:email).uniq
    @ua = Useraccess.ransack(params[:users], search_key: :users)
    @usersMaybe = @ua.result.select('DISTINCT email').paginate(page: params[:users_page], per_page: 10)
    @users = @usersMaybe.to_a
  end


  def delete_user_firmscode
    firmscode = params[:id]
    email = params[:email]
    SystemLog.create(:procedure_name => 'admin_controller', :log_message => "Deleting firmscode access(#{firmscode}) for user: #{email}")

    begin
      usersAccess = Useraccess.where(email: "#{email}").pluck(:firmscode)

      if usersAccess.count == 1
        Useraccess.where(email: email, firmscode: firmscode).update_all(firmscode: '0000')
        flash[:success] = "User access to firmscode deleted and default value set successfully!"
      else
        @selectedUserAccess = Useraccess.where(email: "#{email}", firmscode: firmscode).first

        if @selectedUserAccess.present?
          Useraccess.where(email: "#{email}", firmscode: firmscode).delete_all
          flash[:success] = "User access to firmscode deleted successfully!"
        else
          flash[:danger] = "Could not delete user access to firmscode!"
        end
      end
    rescue StandardError => e
      flash[:danger] = "An error occurred: Contact support with this error code: 12221"
      SystemLog.create(:procedure_name => 'admin_controller', :log_message => "[12221] An error occurred: #{e}")
    end

    respond_to do |format|
      format.js { render inline: 'location.reload();' }
    end
  end


  def edit_user_firmscode
    @current_user = current_user
    @warehouses = Warehousesetup.all
    @usersetup = Useraccess.new
    @email = params[:email]
    @username_if_exists = User.where(email: @email).pluck(:username).first

    @show_firmsaccess_for_user = Useraccess.where(email: @email)
    @pendingWarehouse = Useraccess.where(email: @email).where(warehouse: '0000')

    @firmsCodebyUser = Useraccess.where(email: @email)

    if @username_if_exists.present?
      @username = @username_if_exists
    else
      @username = "Not set"
    end

    respond_to do |format|
      format.turbo_stream { render partial: "admin/edit_user_firmscode" }
      format.html { render partial: "admin/edit_user_firmscode" }
      format.js
    end
  end


  def add_edited_user_firmscode
    # Accessing the parameters
    @email = params[:"/to_the_controller"][:email]
    @warehouse = params[:warehouse]
    @userid = User.where(email: @email).pluck(:id).first
    multiform_params = params[:usersetup][:multiform]
    role = 0

    multiform_params.each do |index, data|
      role = data[:roles].upcase

      defaultFirmsCodeExists = Useraccess.exists?(email: @email, warehouse: '0000')

      if defaultFirmsCodeExists
        Useraccess.where(email: @email, warehouse: '0000').update_all(warehouse: @warehouse)
      else
        if Useraccess.exists?(email: @email, warehouse: @warehouse)
        else
          Useraccess.create(email: @email, warehouse: @warehouse)
        end
      end

      #if role is admin then delete all other roles for user and add the admin role
      #before creating any other role make sure the role does not already exist
      #if multiple roles being added at a time make sure those roles don't clash as well as if there is an admin with it

      #AVAILABLE ROLES:
      #ADMN - Admin(ALL)
      #RCPT - Receipt
      #SHIP - Shipping
      #PROD - Production
      #RCSH - Receipt and shipping
      #RCPD - Receipt and production
      #SHPD - Shipping and production
      if params.dig("usersetup", "multiform")&.values&.any? { |row| row["roles"] == "ADMN" }
        UserWarehouseRole.create(warehouse: @warehouse, role: 'ADMN', user_tabs: 'Receipts', orderid: 1, user_email: @email)
        UserWarehouseRole.create(warehouse: @warehouse, role: 'ADMN', user_tabs: 'Shipments', orderid: 2, user_email: @email)
        UserWarehouseRole.create(warehouse: @warehouse, role: 'ADMN', user_tabs: 'Production', orderid: 3, user_email: @email)
        break

      else
        case role
        when 'RCPT'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'RCPT', user_tabs: 'Receipts', orderid: 1, user_email: @email)
        when 'SHIP'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'SHIP', user_tabs: 'Shipments', orderid: 2, user_email: @email)
        when 'PROD'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'PROD', user_tabs: 'Production', orderid: 3, user_email: @email)
        when 'RCSH'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'RCSH', user_tabs: 'Receipts', orderid: 1, user_email: @email)
          UserWarehouseRole.create(warehouse: @warehouse, role: 'RCSH', user_tabs: 'Shipments', orderid: 2, user_email: @email)
        when 'RCPD'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'RCPD', user_tabs: 'Receipts', orderid: 1, user_email: @email)
          UserWarehouseRole.create(warehouse: @warehouse, role: 'RCPD', user_tabs: 'Production', orderid: 3, user_email: @email)
        when 'SHPD'
          UserWarehouseRole.create(warehouse: @warehouse, role: 'SHPD', user_tabs: 'Production', orderid: 3, user_email: @email)
          UserWarehouseRole.create(warehouse: @warehouse, role: 'SHPD', user_tabs: 'Shipments', orderid: 2, user_email: @email)
        end
      end

      

    end

    flash[:success] = "User access updated successfully!"
    respond_to do |format|
      format.js { render inline: 'location.reload();' }
    end
    #redirect_to smplbw_firmscode_setup_path
  end


  def admin_override
    user_admin = current_user.admin
    if user_admin == true
      @goodToGo = 'true'
      userToBoot = User.find_by(id: session[:other_user])
      @lastSignIn = userToBoot.last_sign_in_at
      @lastActivity = userToBoot.user_actions
      @usernameUserToBoot = userToBoot.username
      render layout: false
    else
      flash[:warning] = "Only admin may perform requested actions"
      redirect_to on_close_path
    end
  end


  def log_user_out
    old_user = session[:other_user]
    user = User.find_by(id: session[:other_user])
    user.update_column(:logged_in, false)
    session[:other_user] = nil
    redirect_to dashboard_path
  end

  def lock_users 
  end

  def finalize_lock_users
    @users = User.update(:user_lock => true)
    flash[:success] = "All users have been locked"
    redirect_to manage_users_redirect_path
  end

  def checkifloggedout
    userid = session[:user_id]
    user = User.find_by(id: userid)
    SystemLog.create(:procedure_name => 'admin_controller', :log_message => "selected userid: #{userid} logged in: #{user.logged_in}")

    if user.logged_in == true
      render json: { status: 'user logged in' }
    else
      SystemLog.create(:procedure_name => 'admin_controller', :log_message => "redirect #{user.logged_in}")
      render json: { status: 'user logged out' }
    end
  end

  private

  def load_manage_users_context
    @u = User.ransack(params[:users])
    @users = @u.result.paginate(page: params[:users_page], per_page: 10)

    @locked_user = User.where(user_lock: true).first
    @ifUserLocked = @locked_user.present? ? 'on' : 'off'

    @useraccess_available = begin
      ActiveRecord::Base.connection.data_source_exists?(Useraccess.table_name)
    rescue ActiveRecord::StatementInvalid
      false
    end

    if @useraccess_available
      @verifiedusers_email = VerifiedUser.pluck(:email)
      @verified_user_action_needed = Useraccess.where(email: @verifiedusers_email, warehouse: '0000').pluck(:email)
      @verified_user_action_needed_count = @verified_user_action_needed.count
    else
      @verifiedusers_email = []
      @verified_user_action_needed = []
      @verified_user_action_needed_count = 0
    end

    @verifiedusers = VerifiedUser.new
    @authusr = SelectedAuthorization.all
    @currentusers = VerifiedUser.select(:email).order(email: :asc)
    @selectedemail = SelectedEmail.new
    @restpasswordusers = User.select(:email).order(email: :asc)
  end

end
