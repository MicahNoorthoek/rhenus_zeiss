class DashboardsController < ApplicationController

    before_action :require_user
    #before_action :last_sign_in

    require 'will_paginate'
    def index
      session[:comment] = nil
      session[:selectedpart] = nil
      Rails.logger.debug "Index action reached"
      @reconciliation = Reconciliation.select("COUNT(part_number) AS count_of_part_number, comments, MIN(part_number) AS min_of_part_number, MAX(part_number) AS max_of_part_number").group(:comments).order(:comments)
    end

    def parts_details
      session[:comment] = params[:comment] if params[:comment].present?
      @comment = params[:comment].presence || session[:comment]
      if @comment.present?

        current_user_id = current_user.id
        record = SelectedComment.find_or_initialize_by(userid: current_user_id)
        record.update(comments: @comment)

        @pd = PartsDetail.ransack(params[:parts], search_key: :parts)
        @partdetails = @pd.result.paginate(page: params[:parts_details_page], per_page: 50)
      else
        SystemLog.create(procedure_name: 'dashboard_controller', log_message: "Tried to display details for comment: #{@comment}, but was unable to!")
        flash[:error] = "Error: Was not able to display details!"
        redirect_to dashboard_path 
      end
    end


    def balance_details
      session[:selectedpart] = params[:selectedpart] if params[:selectedpart].present?
      @selectedPart = params[:selectedpart].presence || session[:selectedpart]
      if @selectedPart.present?

        current_user_id = current_user.id
        record = SelectedPart.find_or_initialize_by(userid: current_user_id)
        record.update(part_number: @selectedPart)

        @balance_details = BalanceDetail.where(part_number: @selectedPart)

        #@bd = BalanceDetail.ransack(params[:parts], search_key: :parts)
        #@balancedetails = @bd.result.paginate(page: params[:balance_details_page], per_page: 50)
      else
        SystemLog.create(procedure_name: 'dashboard_controller', log_message: "Tried to display balance details for part: #{@selectedPart}, but was unable to!")
        flash[:error] = "Error: Was not able to display details!"
        redirect_to dashboard_path 
      end
    end
   
   
  

    def refresh_page
      respond_to do |format|
        format.js { render inline: 'location.replace(location.pathname);'}
      end
    end

end
