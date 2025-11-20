class DeleteModalController < ApplicationController

    before_action :require_user
    #before_action :last_sign_in

    def delete
        @caller = params[:caller]

        case @caller
        when "warehouse_receipts"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_rec")
            @spc = params[:spc]

        when "receipts_details"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_rec_details")
            @spc = params[:spc]
	        @id = params[:id]

        when "warehouse_withdrawals"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_ship")
            @clientpo = params[:clientpo]
      
        when "shipments_details"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_ship_details")
            @clientpo = params[:clientpo]
            @id = params[:id]

        when "warehouse_production"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_prod")
            @production_identifier = params[:production_identifier]  
  
        when "production_details"
                SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "del_prod_details")
                @spc = params[:spc]
                @id = params[:id]    
        
        when "empty_headerqty"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "verify_no_header_qty")
            @spc = params[:spc]

        when "user_creation"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "user")
            @curauth = SelectedAuthorization.pluck(:selected_authorization)

            if @curauth == [true]
                @message = "Are you sure you want to restrict new users from being created?"
            else
                @message = "Are you sure you want to allow new users to be created?"       
            end

        else
            @caller = "Invalid"
            SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "INVALID: #{params[:caller]}, #{params}")
        end

        #respond_to do |format|
        #    format.html { render partial: "delete_modal/delete" } 
        #    format.js 
        #  end


        render partial: "delete_modal/delete"  

        #SystemLog.create(:procedure_name => 'delete_modal_controller', :log_message => "#{params[:caller]}, #{params[:withdrawalentrynumber]}")
      
    end
end
