class UsersController < ApplicationController

  before_action :require_user, except: [:new, :create]
  before_action :require_same_user, only: [:edit, :update, :destroy]
  before_action :require_admin, only: [:destroy]

  def index
    @users = User.where(wms_support: false)
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
    #render partial: "users/edit"  
  end


  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update(user_params)
        flash[:success] = "Your account was updated successfully"
        format.html{ redirect_to dashboard_path }
        format.js { render js: 'location.reload();'}
      else
        format.html do
          flash[:danger] = "Did not update new user"
          render 'edit'
        end
        format.js { render 'edit'}
      end
    end
  end

  def create
    if user_params[:email].present?
      user_by_email = User.find_by(email: user_params[:email])

    if !user_by_email.present?
    @user = User.create(user_params)

    verifyemail = VerifiedUser.where(:email => @user.email)

    if verifyemail.exists?
      if @user.save
        #ReportMailer.with(user: @user).welcome_email.deliver_now


        @user_signin = User.all
        @THEuser

        @login_block = false
     #   @user_signin.each do |user_check|
     #     if user_check.logged_in == true
     #       @login_block = true
     #       @THEuser = user_check.id
     #       break  # No need to continue the loop if one user is logged in
     #     end
     #   end

     #   if @login_block == false || @THEuser == @user.id
     if @login_block == false
          session[:user_id] = @user.id

          auth_warehouse_for_user = Useraccess.where(email: User.where(id: session[:user_id]).pluck(:email).first).order(warehouse: :desc).pluck(:warehouse).first
  
          session[:warehouse] = auth_warehouse_for_user
          SystemLog.create(:procedure_name => 'users_controller', :log_message => "session declared selected warehouse: #{auth_warehouse_for_user}")

          selected_warehouse = Selectedwarehouse.where(userid: session[:user_id]).first || Selectedwarehouse.new
          if Selectedwarehouse.count == 0
            Selectedwarehouse.create(warehouse: auth_warehouse_for_user, userid: session[:user_id])
          else
            selected_warehouse.update(warehouse: auth_warehouse_for_user, userid: session[:user_id])
          end


            user = User.find_by(id: session[:user_id])
            user.update_column(:logged_in, true)
            flash[:success] = "Successfully created new user"
            redirect_to dashboard_path

        else
          #@auth = SelectedAuthorization.first
          #@auth.update(selected_authorization: false)

          user = User.find_by(id: @user.id)
          user.update_column(:logged_in, false)

          flash[:success] = "Successfully created new user! A seperate user is currently logged on. For data integrity purposes SMPLBW allows only one user at a time"
          redirect_to root_path
        end

      else
         flash[:danger] = "Did not create new user"
         redirect_to createuser_38923489d8234k234_path
      end

    else

        @auth = SelectedAuthorization.first
        @auth.update(selected_authorization: false)
        User.where(:email => @user.email).delete_all

        redirect_to createuser_38923489d8234k234_path
        flash[:danger] = "Unauthorized to create an account."

    end
    else
      redirect_to createuser_38923489d8234k234_path
      flash[:danger] = "Email already in use."
    end
    else
      redirect_to createuser_38923489d8234k234_path
      flash[:danger] = "Email must not be empty."
    end
  end

  def show
    @users = User.where(wms_support: false)
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:success] = "User has been deleted"
    redirect_to root_path
  end

  def toggle_lock_status
    @user = User.find(params[:id])
    @user.update_column(:login_attempts, 0) if @user.user_lock == true
    @user.toggle!(:user_lock)
    render inline: 'location.reload();'
  end

  def toggle_auto_email
    @user = User.find(params[:id])
    @user.toggle!(:auto_email)
    render inline: 'location.reload();'
  end

  def toggle_undo_shipment_lock
    @user = User.find(params[:id])
    @user.toggle!(:undo_shipments_lock)
    render inline: 'location.reload();'
  end

  def toggle_client_admin
    @user = User.find(params[:id])
    @user.toggle!(:client_admin)
    render inline: 'location.reload();'
  end

  def all_user_lock
    update_params = {user_lock: params[:is_locked]}
    update_params[:login_attempts] = 0 if params[:is_locked] == false
    @users = User.update_all(update_params)
  end

  private
  def user_params
    params.require(:user).permit(:username, :email, :company, :password, :admin, :subdomain)
  end

  def require_same_user
    if current_user != @user and !current_user.admin?
      flash[:danger] = "You must be logged in to access requested page."
    end
  end

  def require_admin
    if logged_in? and !current_user.admin?
      flash[:danger] = "Only admin users can perform requested action."
      redirect_to root_path
    end
  end

  end
