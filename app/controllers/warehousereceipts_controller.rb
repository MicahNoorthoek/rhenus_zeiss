class WarehousereceiptsController < ApplicationController
    before_action :require_user
    #before_action :last_sign_in
    before_action :authorizedScreens

    def new
      begin
	      error_messages = []

        spc = new_receipt_params[:spc].strip
        if spc.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "SPC contains invalid characters."
        end

        clientpo = new_receipt_params[:clientpo].strip
        if clientpo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Client PO contains invalid characters."
        end

        caja = new_receipt_params[:caja].strip
        if caja.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Caja contains invalid characters."
        end

        sello = new_receipt_params[:sello].strip
        if sello.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Sello contains invalid characters."
        end

        if error_messages.any?
          flash[:danger] = error_messages.join(" ")
          session[:WRCERROR] = 'ERROR'
          session[:wrc_params] = new_receipt_params
          redirect_to warehouse_receipts_path and return
        end



        existing_receipt = SpcReceipt.find_by(spc: new_receipt_params[:spc], warehouse: new_receipt_params[:warehouse])
        archived_existing_receipt = SpcReceiptsArchive.find_by(spc: new_receipt_params[:spc], warehouse: new_receipt_params[:warehouse])
        if existing_receipt || archived_existing_receipt
          if archived_existing_receipt
            flash[:danger] = "An archived receipt already exists for entered SPC: #{new_receipt_params[:spc]}"
          else
            flash[:danger] = "Receipt already exists for entered SPC: #{new_receipt_params[:spc]}"
          end
          session[:WRCERROR] = 'ERROR'
          session[:wrc_params] = new_receipt_params
          redirect_to warehouse_receipts_path
        else
          defaulted_params = default_carton_params(new_receipt_params)
          
          @receipt = SpcReceipt.create(defaulted_params)
          if @receipt.save
            flash[:success] = "Saved Successfully"
            redirect_to warehouse_receipts_path
          else
            flash[:danger] = "There was a problem"
            redirect_to warehouse_receipts_path
          end
        end
        
      rescue => e
        SystemLog.create(:procedure_name => 'warehouse_receipts_controller', :log_message => "Error: #{e}")
        session[:WRCERROR] = 'ERROR'
        session[:wrc_params] = defaulted_params

        flash[:danger] = "Unknown error: Check system logs"
        redirect_to warehouse_receipts_path
      end
    end


    def update
      begin       
        
        error_messages = []

        clientpo = update_receipt_params[:clientpo].strip
        if clientpo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Client PO contains invalid characters."
        end

        caja = update_receipt_params[:caja].strip
        if caja.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Caja contains invalid characters."
        end

        sello = update_receipt_params[:sello].strip
        if sello.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Sello contains invalid characters."
        end

        if error_messages.any?
          flash[:danger] = error_messages.join(" ")
          session[:WRCERROR] = 'ERROR'
          session[:wrc_params] = update_receipt_params
          redirect_to warehouse_receipts_path and return
        end

        @result = ActiveRecord::Base.connection.execute("select spcwms.update_receipts(
          '#{update_receipt_params[:spc]}', 
          '#{update_receipt_params[:releasedate]}', 
          '#{placeholder_cleanup(update_receipt_params[:client])}',
          '#{update_receipt_params[:clientpo]}', 
          '#{update_receipt_params[:caja]}', 
          '#{update_receipt_params[:sello]}', 
          #{selection_or_null(update_receipt_params[:cartons30lb])}, 
          #{selection_or_null(update_receipt_params[:cartons10lb])}, 
          #{selection_or_null(update_receipt_params[:cartons5lb])});
        ")
        if @result.first['update_receipts'] == 'RECORDED'
          flash[:success] = "Receipt updated successfully"
          redirect_to warehouse_receipts_path
        else
          flash[:danger] = @result.first['update_receipts']
          redirect_to warehouse_receipts_path
        end
  
      rescue => e
        SystemLog.create(procedure_name: 'warehousereceipts_controller', log_message: "Error: #{e}")
        flash[:danger] = "An unknown error occurred. Check system logs."

        redirect_to warehouse_receipts_path
      end
    end


    def update_receipts
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @updatereceipts = SpcReceipt.find_by(spc: params[:spc], warehouse: @userWarehouse)
      @client = Client.all
      
      if @updatereceipts.nil?
        flash[:danger] = "Record not found"
        redirect_to warehouse_receipts_path
      else
        @update_receipt_params = {
          spc: @updatereceipts.spc,
          releasedate: @updatereceipts.releasedate,
          client: @updatereceipts.client,
          clientpo: @updatereceipts.clientpo,
          caja: @updatereceipts.caja,
          sello: @updatereceipts.sello,
          cartons30lb: @updatereceipts.cartons30lb,
          cartons10lb: @updatereceipts.cartons10lb,
          cartons5lb: @updatereceipts.cartons5lb
        }
      end
    end


    def delete_receipt
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @spc = params[:spc]

      if @spc.present?
        @result = ActiveRecord::Base.connection.execute("select spcwms.delete_receipt('#{@spc}', '#{@userWarehouse}');")

        if @result[0]['delete_receipt'] == 'DELETED'
          flash[:success] = @result[0]['delete_receipt']
          redirect_to warehouse_receipts_path
        else
          flash[:danger] = @result[0]['delete_receipt']
          redirect_to warehouse_receipts_path
        end
      else
        SystemLog.create(:procedure_name => 'warehouse_receipts_controller', :log_message => "Could not delete receipt due to spc variable not present: #{@spc}")
        flash[:danger] = "Unable to delete selected receipt. Please contact support."
        redirect_to warehouse_receipts_path
      end
    end


    def archive_receipt
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @spc = params[:spc]
      @results = SpcReceipt.where(warehouse: @userWarehouse).where(spc: @spc)
      
      if @results.present?
        ActiveRecord::Base.connection.execute("CALL archive_receipt('#{@spc}', '#{@userWarehouse}');")

        @message = ProcedureMessage.find_by(procedureid: 3)
        if @message.message.present?
          if @message.message.include?('Success')
            flash[:success] = @message.message
            redirect_to warehouse_receipts_path
          else
            flash[:warning] = @message.message
            redirect_to warehouse_receipts_path
          end
        else
          flash[:warning] = "Could not get response from archive procedure"
          redirect_to warehouse_receipts_path
        end
      else
        @archivedResults = SpcReceiptsArchive.where(warehouse: @userWarehouse).where(spc: @spc)
        if @archivedResults.present?
          flash[:warning] = "SPC: #{@spc} receipt has already been archived"
          redirect_to warehouse_receipts_path
        else
          flash[:warning] = "Found no receipt to archive. SPC: #{@spc}"
          redirect_to warehouse_receipts_path
        end
      end
    end

    private

    def new_receipt_params
      params.require('/warehouse_receipts').permit(
        :spc,
        :releasedate,
        :clientpo,
        :caja,
        :sello,
        :cartons30lb,
        :cartons10lb,
        :cartons5lb 
      ).merge(client: placeholder_cleanup(params[:client])).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
    end

    def update_receipt_params
      params.require(:spc_receipt).permit(
        :spc,
        :releasedate,
        :clientpo,
        :caja,
        :sello,
        :cartons30lb,
        :cartons10lb,
        :cartons5lb
      ).merge(client: placeholder_cleanup(params[:client])).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
    end
    
    def default_carton_params(params)
      defaulted_params = params.dup
      carton_keys = [:cartons30lb, :cartons10lb, :cartons5lb]
    
      carton_keys.each do |key|
        defaulted_params[key] = 0 if defaulted_params[key].blank?
      end
    
      defaulted_params
    end


    def placeholder_cleanup(value)
      value.nil? || value.strip.empty? || value.include?('Select') ? '' : "#{value}"
    end

    def selection_or_null(value)
      value.nil? || value.strip.empty? ? 'NULL' : "#{value}"
    end
#.merge(warehouse: params[:warehouse]).merge(customerpartnumber: params[:customerpartnumber])
end
