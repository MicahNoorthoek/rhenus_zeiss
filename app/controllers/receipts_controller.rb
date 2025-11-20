class ReceiptsController < ApplicationController
    before_action :authorizedScreens
    before_action :require_user
    #before_action :last_sign_in


    def create
      begin
      error_messages = []

        lbo = new_receipt_details_params[:lbo].strip
        if lbo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "LBO contains invalid characters."
        end

        pallet = new_receipt_details_params[:pallet].strip
        if pallet.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Pallet contains invalid characters."
        end

        lot = new_receipt_details_params[:lot].strip
        if lot.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Lot contains invalid characters."
        end

        if error_messages.any?
          flash[:danger] = error_messages.join(" ")
          session[:WRCERROR] = 'ERROR'
          session[:wrc_params] = new_receipt_details_params
          redirect_to receipts_details_path(spc: new_receipt_details_params[:spc]) and return
        end

        @receiptdetails = SpcReceiptsDetail.new(new_receipt_details_params)
        if @receiptdetails.save#(new_receipt_details_params)
          flash[:success] = "Saved Successfully"
          redirect_to receipts_details_path(spc: @receiptdetails.spc)
        else
          flash[:danger] = "There was a problem"
          redirect_to receipts_details_path(spc: new_receipt_details_params[:spc])
        end
        
      rescue => e
        SystemLog.create(:procedure_name => 'receipts_details_controller', :log_message => "Error: #{e}")
        session[:WRCERROR] = 'ERROR'
        session[:wrc_params] = new_receipt_details_params

        flash[:danger] = "Unknown error: Check system logs"
        redirect_to receipts_details_path(spc: new_receipt_details_params[:spc])
      end
    end

    def receipts_details
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      if session[:WRCERROR] == 'ERROR'
        @receipts_params = session[:wrc_params]
      else
        session[:wrc_params] = ''
        session[:WRCERROR] = ''
      end

      session[:wrc_params] = ''
      session[:WRCERROR] = ''

      @codigo = SkuMaster.all
      if params[:spc].present?
        @current_spc = params[:spc]
        @receiptdetails = SpcReceiptsDetail.where(warehouse: @userWarehouse).where(spc: params[:spc]).order(id: :desc).paginate(page: params[:receipts_details_page], per_page: 20)
        result = SpcReceipt.where(spc: params[:spc]).where(warehouse: @userWarehouse)
                .select("SUM(COALESCE(cartons30lb, 0)) AS carton30_sum") 
                .select("SUM(COALESCE(cartons10lb, 0)) AS carton10_sum")
                .select("SUM(COALESCE(cartons5lb, 0)) AS carton5_sum")
                .take
        @carton30_sum = result.carton30_sum * 30
        @carton10_sum = result.carton10_sum * 10
        @carton5_sum = result.carton5_sum * 5

        @expected_cases = @carton30_sum + @carton10_sum + @carton5_sum

        @total_cases = SpcReceiptsDetail.where(warehouse: @userWarehouse)
                      .where(spc: params[:spc])
                      .sum("CASE 
                              WHEN uom = 'CAS30' THEN quantity_remaining * 30
                              WHEN uom = 'CAS10' THEN quantity_remaining * 10
                              WHEN uom = 'CAS05' THEN quantity_remaining * 5
                              ELSE quantity_remaining
                            END")


        #@total_cases = SpcReceiptsDetail.where(warehouse: @userWarehouse).where(spc: params[:spc]).sum(:quantity_remaining)



        @countries = CountriesOfOrigin.all
        @linenoVal = SpcReceiptsDetail.where(warehouse: @userWarehouse).where(spc: @current_spc).maximum(:lineno) || 0
      else
        flash[:warning] = "Could not view details. Please try again."
        redirect_to warehouse_receipts_path
      end
    end

    def update
      begin

      error_messages = []

        lbo = update_receipt_details_params[:lbo].strip
        if lbo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "LBO contains invalid characters."
        end

        pallet = update_receipt_details_params[:pallet].strip
        if pallet.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Pallet contains invalid characters."
        end

        lot = update_receipt_details_params[:lot].strip
        if lot.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          error_messages << "Lot contains invalid characters."
        end

        if error_messages.any?
          flash[:danger] = error_messages.join(" ")
          session[:WRCERROR] = 'ERROR'
          session[:wrc_params] = update_receipt_details_params
          redirect_to receipts_details_path(spc: update_receipt_details_params[:spc]) and return
        end


        Rails.logger.debug "ID: #{update_receipt_details_params[:id]}"
        @result = ActiveRecord::Base.connection.execute("select spcwms.update_receipt_details(
          '#{update_receipt_details_params[:spc]}', 
          #{selection_or_null(update_receipt_details_params[:lineno])}, 
          '#{update_receipt_details_params[:codigo]}', 
          '#{update_receipt_details_params[:pallet]}', 
          '#{update_receipt_details_params[:lot]}', 
          '#{update_receipt_details_params[:lbo]}', 
          #{update_receipt_details_params[:quantity]}, 
          '#{update_receipt_details_params[:uom]}', 
          '#{update_receipt_details_params[:coo]}', 
          '#{update_receipt_details_params[:freezernum]}', 
          '#{update_receipt_details_params[:racknum]}', 
          '#{update_receipt_details_params[:side]}', 
          '#{update_receipt_details_params[:location]}', 
          #{update_receipt_details_params[:id]});
        ")
        if @result.first['update_receipt_details'] == 'RECORDED'
          flash[:success] = "Receipt details updated successfully"
          redirect_to receipts_details_path(spc: update_receipt_details_params[:spc])
        else
          flash[:danger] = @result.first['update_receipt_details']
          redirect_to update_receipt_details_path(id: update_receipt_details_params[:id])
        end
  
      rescue => e
        SystemLog.create(procedure_name: 'receipts_controller', log_message: "Error: #{e}")
        flash[:danger] = "An unknown error occurred. Check system logs."

        redirect_to update_receipt_details_path(id: update_receipt_details_params[:id])
      end
    end


    def update_receipts_details
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      Rails.logger.info "Received parameters: #{params.inspect}"
      @receiptdetail = SpcReceiptsDetail.find_by(id: params[:id], warehouse: @userWarehouse)
      #SystemLog.create(:procedure_name => 'receipts_controller', :log_message => "Update receipt details for ID: #{params[:id]} in warehouse: #{@userWarehouse} with freezernum: #{@receiptdetail.freezernum}") if @receiptdetail
      @codigo = SkuMaster.all
      @countries = CountriesOfOrigin.all
      
      if @receiptdetail.nil?
        flash[:danger] = "Record not found"
        redirect_to receipts_details_path(id: params[:id])
      else
        @update_receipts_params = {
          spc: @receiptdetail.spc,
          lineno: @receiptdetail.lineno,
          codigo: @receiptdetail.codigo,
          pallet: @receiptdetail.pallet,
          lot: @receiptdetail.lot,
          lbo: @receiptdetail.lbo,
          quantity: @receiptdetail.quantity,
          uom: @receiptdetail.uom,
          coo: @receiptdetail.coo,
          freezernum: @receiptdetail.freezernum,
          racknum: @receiptdetail.racknum,
          side: @receiptdetail.side,
          location: @receiptdetail.location,
          id: @receiptdetail.id
        }

        Rails.logger.info "Update parameters: #{@update_receipts_params.inspect}"
      end
    end
    

    def delete_receipt_details
      #@userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @id = params[:id]

      if @id.present?
        @receiptdetail = SpcReceiptsDetail.find_by(id: @id)
        if @receiptdetail
          @spc = @receiptdetail.spc
          #@result = ActiveRecord::Base.connection.execute("select spcwms.delete_receipt_details('#{@spc}', '#{@userWarehouse}');")
          @result = ActiveRecord::Base.connection.execute("select spcwms.delete_receipt_details('#{@id}');")

          if @result[0]['delete_receipt_details'] == 'DELETED'
            flash[:success] = @result[0]['delete_receipt_details']
            redirect_to receipts_details_path(spc: @spc)
          else
            flash[:danger] = @result[0]['delete_receipt_details']
            redirect_to receipts_details_path(spc: @spc)
          end
        else
          flash[:danger] = "Receipt detail not found."
          redirect_to receipts_details_path(spc: params[:spc])
        end  
      else
        SystemLog.create(:procedure_name => 'receipts_controller', :log_message => "Could not delete receipt details due to spc variable not present: #{@id}")
        flash[:danger] = "Unable to delete selected receipt. Please contact support."
        redirect_to receipts_details_path(spc: params[:spc])
      end
    end
    

    private

    def new_receipt_details_params
      params.require('/receipts_details').permit(
        :spc,
        :lineno,
        :codigo,
        :pallet,
        :lot,
        :lbo,
        :quantity,
        :uom,
        :quantity_remaining,
        :freezernum,
        :racknum,
        :side,
        :location
      ).merge(codigo: params[:codigo]).merge(uom: params[:uom]).merge(receipt_type: 'RECEIPT').merge(recorded_by_username: current_user.username).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first).merge(coo: params[:coo])
    end

    def update_receipt_details_params
      params.require(:spc_receipts_detail).permit(
        :spc,
        :lineno,
        :pallet,
        :lot,
        :lbo,
        :quantity,
        :id, 
        :freezernum,
        :racknum,
        :side,
        :location
      ).merge(codigo: params[:codigo]).merge(coo: params[:coo]).merge(uom: params[:uom])
    end

    def zeroCartons(value)
      value[:cartons30lb].nil? || value.strip.empty? ? 'NULL' : "#{value}"
    end

    def selection_or_null(value)
      value.nil? || value.strip.empty? ? 'NULL' : "#{value}"
    end

      
end
