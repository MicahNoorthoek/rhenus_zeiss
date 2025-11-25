class VerifiedUsersController < ApplicationController
  before_action :set_email
  #before_action :last_sign_in
  before_action :require_admin

  def create
    @verifiedusers = VerifiedUser.create(verifieduser_params)
    if @verifiedusers.save
        flash[:success] = "New verified User has been created."
        email = @verifiedusers.email
        #SendlinkMailer.with(email: email).sendlink.deliver_now
        redirect_to manage_users_redirect_path
    else
      flash[:danger] = "New verified User has not been created. User may already exist."
      redirect_to manage_users_redirect_path
    end
  end

  private
    def verifieduser_params
      params.require(:verified_user).permit(:email)
    end

    def set_email
      params[:verified_user][:email] = params[:verified_user][:email]&.downcase
    end

  end
