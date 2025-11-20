class DashboardsController < ApplicationController

    before_action :require_user
    #before_action :last_sign_in
    before_action :authorizedScreens

    require 'will_paginate'
    def index
      Rails.logger.debug "Index action reached"
      #SendwithdrawalMailer.sendwithdrawal.deliver_now
      #SystemLog.create(:procedure_name => 'generate_form_300_report_controller', :log_message => "#{session[:form300reports]}")
      if session[:ftzboardreports] == 'CLEAREDTOREPORT'
        @generate_reports = 'CLEAREDTOREPORT'
      else
        @generate_reports = ''
      end

      @selected_warehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first

      # COMMENTED OUT BY VENERA SONKINA ON 10/22/2024
      #USED WITH ALTERNATE DASHBOARD LAYOUT
      #@discrepancies = Discrepancies.all
      #@warehousereceiptheaders = Warehousereceiptheader.where("quantityonhand <= 0 AND closedreporteddate IS NULL")
      #Useraccess.where(email: User.where(id: session[:user_id]).pluck(:email).first).order(firmscode: :desc).pluck(:firmscode).first
      #available_firmscodes = Useraccess.where(email: User.where(id: session[:user_id]).pluck(:email).first).order(firmscode: :desc).pluck(:firmscode)
      #SystemLog.create(:procedure_name => 'dashboards_controller', :log_message => "#{available_firmscodes.count}")
      #@form300referencedata = Form300referencedata.where(firmscode: available_firmscodes).all
      
      #@useraccess_ifpending = Warehousesetup.where(firmscode: Useraccess.where(email: @current_user.email).pluck(:firmscode))

      #@firmscodeCount = form300referencedata.where(firmscode: available_firmscodes).count
    end


    def warehouse_receipts_form
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      if session[:WRCERROR] == 'ERROR'
        @receipts_params = session[:wrc_params]
      else
        session[:wrc_params] = ''
        session[:WRCERROR] = ''
      end

      session[:wrc_params] = ''
      session[:WRCERROR] = ''
      #@part_numbers = Partnumber.all
      #@receipts = Selectedwarehousereceipt.all.ransack(params[:receipts_page]).result.order(receiptdate: :desc).paginate(page: params[:receipts_page], per_page: 30)
      @client = Client.all
      @receipts = SpcReceipt.where(warehouse: @userWarehouse).ransack(params[:receipts_page]).result.order(id: :desc).paginate(page: params[:receipts_page], per_page: 30)
    end


    def warehouse_withdrawals_form
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      if session[:withdrawal_recorded] == 'RECORDED'
        @reportedstatus = session[:reportedstatus]
        @generate_reports = 'CLEAREDTOREPORT'
        session[:wwc_params] = ''
        session[:ERROR] = ''
      else
        @generate_reports = ''
        @reportedstatus = ''
        @withdrawal_params = session[:wwc_params]
      end

      session[:wwc_params] = ''
      session[:ERROR] = ''
      session[:reportedstatus] = ''

      @client = Client.all
      @shipments = SpcShipment.where(warehouse: @userWarehouse).ransack(params[:withdrawals_page]).result.order(releasedate: :desc).paginate(page: params[:withdrawals_page], per_page: 30)
      
      #@part_numbers = Partnumber.all
      #@withdrawals = Selectedwarehousewithdrawal.all
      #@withdrawals = Selectedwarehousewithdrawal.all.ransack(params[:withdrawals_page]).result.order(salesdate: :desc).paginate(page: params[:withdrawals_page], per_page: 30)
      #@editable_withdrawal = Selectedwarehousewithdrawal.order(salesid: :desc).first
    end


    def warehouse_production_form
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      if session[:WPCERROR] == 'ERROR'
        @prod_params = session[:wpc_params]
      else
        session[:wpc_params] = ''
        session[:WPCERROR] = ''
      end

      session[:wpc_params] = ''
      session[:WPCERROR] = ''

      @process = ProcessType.where(warehouse: @userWarehouse).all
      @codigo = SkuMaster.all
      @prod = SpcProduction.where(warehouse: @userWarehouse).ransack(params[:prod_page]).result.order(releasedate: :desc).paginate(page: params[:prod_page], per_page: 30)
    end


    def inventory_screen
      @inv = InventoryView.where(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first).ransack(params[:inventory_research], search_key: :inventory_research)
      @inventory =  @inv.result.order(recording_timestamp: :asc).paginate(page: params[:inventory_page], per_page: 40)
    end


    def report_balances_form
      if session[:BCERROR] == 'ERROR'
        @balance_params = session[:bc_params]
      else
        session[:bc_params] = ''
      end

      if session[:recalculated_with_btn] == 'SHOWDISCREPMESSAGE'
        @recalculated_with_btn = 'SHOWDISCREPMESSAGE'
        session[:excludeCalculateBalanceFunction] = 'true'
      end

      session[:recalculated_with_btn] = ''
      session[:bc_params] = ''
      session[:BCERROR] == ''
      @selected_warehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @selectedpart = Reportedbalance.where(warehouse: @selected_warehouse).all
      @part_numbers = Partnumber.all
      @reported_balances = Balancedate.ransack(params[:reported_balances_page]).result.order(balancedate: :desc).paginate(page: params[:reported_balances_page], per_page: 30)
      @reported_balances = Reportedbalance.where(warehouse: @selected_warehouse).ransack(params[:reported_balances_page]).result.order(balancedate: :desc).paginate(page: params[:reported_balances_page], per_page: 30)
      
      if session[:flash_message] != nil
        flash[:success] = session[:flash_message]
        session[:flash_message] = nil
      else
        session[:flash_message] = nil
      end
    end


    def warehouse_archives
    end


    def updating_selectedwarehouse_by_dropdown
      begin
        selected_warehouse_for_logs = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        new_selected_warehouse = params[:new_warehouse]
        
        if Useraccess.where(email: current_user.email).where(warehouse: new_selected_warehouse).present?

          selected_warehouse = Selectedwarehouse.where(userid: current_user.id).first || Selectedwarehouse.new
          
          selected_warehouse.warehouse = new_selected_warehouse
          if selected_warehouse.userid != current_user.id
            selected_warehouse.userid = current_user.id
          end

          if selected_warehouse.save
            User.where(id: current_user.id).update(recent_warehouse: new_selected_warehouse)
            SystemLog.create(:procedure_name => 'dashboards_controller', :log_message => "Changed warehouse from: #{selected_warehouse_for_logs} to: #{new_selected_warehouse}")
          else
            SystemLog.create(:procedure_name => 'dashboards_controller', :log_message => "Could not change warehouse. Parameters: (from) #{selected_warehouse_for_logs} (to) #{new_selected_warehouse}")
            flash[:danger] = "Error in selecting warehouse"
          end
        else
          SystemLog.create(:procedure_name => 'dashboards_controller', :log_message => "Invalid or unauthorized warehouse selected - user: #{current_user.email} warehouse select attempt: #{new_selected_warehouse}")
          flash[:danger] = "Invalid or unauthorized warehouse selected"
        end
      rescue => e
        flash[:danger] = "There was an error in changing selected warehouse"
        SystemLog.create(:procedure_name => 'dashboards_controller', :log_message => "#{current_user.id} Code Error: #{e}")
      end
    end



    def refresh_page
      respond_to do |format|
        format.js { render inline: 'location.replace(location.pathname);'}
      end
    end

    def testing
    end

end
