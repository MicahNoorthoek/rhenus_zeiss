class VerifiedUsersController < ApplicationController
  before_action :set_email
  #before_action :last_sign_in
  before_action :require_admin

  def create
    @verifiedusers = VerifiedUser.create(verifieduser_params)
    if @verifiedusers.save
      @userWarehouse = Useraccess.create(email: verifieduser_params[:email], warehouse: '0000')
      if @userWarehouse.save
        flash[:success] = "New verified User has been created."
        email = @verifiedusers.email
        SendlinkMailer.with(email: email).sendlink.deliver_now
        redirect_to smplbw_users_path
      else
        flash[:success] = "New verified User has been created. Warning: Could not save set default firms code."
        redirect_to smplbw_users_path
      end
    else
      flash[:danger] = "New verified User has not been created. User may already exist."
      redirect_to smplbw_users_path
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
