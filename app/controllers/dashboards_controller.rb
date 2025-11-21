class DashboardsController < ApplicationController

    before_action :require_user
    #before_action :last_sign_in

    require 'will_paginate'
    def index
      session[:comment] = nil
      Rails.logger.debug "Index action reached"
      @reconciliation = Reconciliation.select("COUNT(part_number) AS count_of_part_number, comments, MIN(part_number) AS min_of_part_number, MAX(part_number) AS max_of_part_number").group(:comments).order(:comments)
    end

    def parts_details
      session[:comment] = params[:comment] if params[:comment].present?
      @comment = params[:comment].presence || session[:comment]
      if @comment.present?
        record = SelectedComment.first_or_initialize
        record.update(comments: @comment)
        @pd = PartsDetail.ransack(params[:parts], search_key: :parts)
        @partdetails = @pd.result.paginate(page: params[:parts_details_page], per_page: 50)
      else
        SystemLog.create(procedure_name: 'dashboard_controller', log_message: "Tried to display details for comment: #{@comment}, but was unable to!")
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
