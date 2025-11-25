class PasswordsController < ApplicationController
  def create
    email = params[:email] #&& params[:password][:email]

    if email
      @user = User.find_by(email: email)
      if @user.present?
        urlcompany = Rails.application.credentials[:url][:local_url]
        @url = "#{urlcompany}reset_password"


     #   SendlinkMailer.with(email: email).sendforgetpasswordlink.deliver_now
        SelectedAuthorization.first_or_create
        SelectedAuthorization.update(:selected_authorization => true)
        #UserTimerWorker.perform_in(15.minutes)
        #flash[:success] = "Email has been sent."
        flash[:success] = "Forgot password link has been sent"
      else
        flash[:danger] = "Email not associated with user"
      end
    else
      flash[:danger] = "Email has not been sent"
    end
    redirect_to manage_users_redirect_path
  end

  def edit
    if current_user.present?
      user = User.find_by(id: current_user.id)
      if user
        @user_company = user.company
      end
    end

    if !SelectedAuthorization.any?(&:selected_authorization)
      flash[:danger] = "Your reset password link has expired"
      redirect_to root_path
    end
  end

  def update_password
    user = User.get_user_by_username_and_company(params[:password][:username], params[:password][:company]).first
    if user && user.update(password: params[:password][:password])
      SelectedAuthorization.update(:selected_authorization => false)
      flash[:success] = "Password updated successfully"
      redirect_to root_path
    else
      flash[:danger] = "Failed to update password. Please try again."
      redirect_to reset_password_path
    end
  end
end
