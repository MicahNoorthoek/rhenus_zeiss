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
    respond_to do |format|
      format.turbo_stream { render partial: "users/user_form", locals: { is_new_record: @user.new_record? } }
      format.html { render partial: "users/user_form", locals: { is_new_record: @user.new_record? }, layout: false }
      format.js   # renders app/views/users/edit.js.erb
    end
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
    begin
    #SystemLog.create(:procedure_name => 'users_controlled', :log_message => "begin: #{user_params.inspect}")
    if user_params[:email].present?
      user_by_email = User.find_by(email: user_params[:email])

    if !user_by_email.present?
    @user = User.create(user_params)

    verifyemail = VerifiedUser.where("LOWER(email) = LOWER(?)", @user.email)
    #SystemLog.create(:procedure_name => 'users_controlled', :log_message => "verifyemail: #{verifyemail.inspect}")
    if verifyemail.exists?
      if @user.save
        @user_signin = User.all
    
          session[:user_id] = @user.id

            user = User.find_by(id: session[:user_id])
            user.update_column(:logged_in, true)
            flash[:success] = "Successfully created new user"
            redirect_to dashboard_path

      else
         flash[:danger] = "Did not create new user"
         redirect_to createuser_38923489d8234k234_path
      end

    else
        SystemLog.create(:procedure_name => 'users_controlled', :log_message => "unauthorized email: #{@user.email}")
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
    rescue => exception
      SystemLog.create(:procedure_name => 'users_controlled', :log_message => "error #{exception.message}")
      @auth = SelectedAuthorization.first
      @auth.update(selected_authorization: true)
      redirect_to createuser_38923489d8234k234_path
      flash[:danger] = "An error occurred while creating the account."
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
