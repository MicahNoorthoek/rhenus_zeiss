class AdminsController < ApplicationController
  def users_zeiss
    @u = User.ransack(params[:users])
    @users = @u.result.paginate(page: params[:users_page], per_page: 10)
  end

   def verify_user
    @verifiedusers = VerifiedUser.new
    @currentusers = VerifiedUser.select(:email).order(email: :asc)

    render partial: "admin/verify_user"  
  end
    
end