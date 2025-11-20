class ProductionsController < ApplicationController
    before_action :authorizedScreens
    before_action :require_user
    #before_action :last_sign_in

    def productions_details
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        if params[:production_identifier].present?
          session[:assignmentRecipient] = params[:production_identifier]
        end
        @production_identifier = params[:production_identifier]
        @productionDetails = SpcReceiptsDetail.where(warehouse: @userWarehouse).where(production_identifier: params[:production_identifier]).all.ransack(params[:details_page]).result.order(lineno: :desc).paginate(page: params[:details_page], per_page: 15)

        @qty = SpcReceiptsDetail.where(warehouse: @userWarehouse)
                  .where(production_identifier: params[:production_identifier])
                  .sum("CASE 
                          WHEN uom = 'CAS30' THEN quantity_remaining * 30
                          WHEN uom = 'CAS10' THEN quantity_remaining * 10
                          WHEN uom = 'CAS05' THEN quantity_remaining * 5
                          ELSE quantity_remaining
                        END")
    end
     

      def update
        begin

          error_messages = []

          lbo = update_productions_details_params[:lbo].strip
          if lbo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "LBO contains invalid characters."
          end
  
          pallet = update_productions_details_params[:pallet].strip
          if pallet.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "Pallet contains invalid characters."
          end
  
          lot = update_productions_details_params[:lot].strip
          if lot.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "Lot contains invalid characters."
          end
  
          if error_messages.any?
            flash[:danger] = error_messages.join(" ")
            session[:WRCERROR] = 'ERROR'
            session[:wrc_params] = update_productions_details_params
            redirect_to productions_details_path(production_identifier: update_productions_details_params[:production_identifier]) and return
          end

          @result = ActiveRecord::Base.connection.execute("select spcwms.update_production_details(
            '#{update_productions_details_params[:spc]}', 
            #{selection_or_null(update_productions_details_params[:lineno])}, 
            '#{update_productions_details_params[:codigo]}', 
            '#{update_productions_details_params[:pallet]}', 
            '#{update_productions_details_params[:lot]}', 
            '#{update_productions_details_params[:lbo]}', 
            '#{update_productions_details_params[:quantity]}', 
            '#{update_productions_details_params[:uom]}', 
            '#{update_productions_details_params[:production_identifier]}', 
            '#{update_productions_details_params[:recording_timestamp]}',
            #{update_productions_details_params[:id]});
          ")
          
          
          if @result.first['update_production_details'] == 'RECORDED'
            flash[:success] = "Production details updated successfully"
            redirect_to productions_details_path(production_identifier: update_productions_details_params[:production_identifier])
          else
            flash[:danger] = @result.first['update_production_details']
            redirect_to update_productions_details_path(production_identifier: update_productions_details_params[:production_identifier])
          end
    
        rescue => e
          SystemLog.create(procedure_name: 'productions_controller', log_message: "Error: #{e}")
          flash[:danger] = "An unknown error occurred. Check system logs."
  
          redirect_to update_productions_details_path(production_identifier: update_productions_details_params[:production_identifier])
        end
      end
  
  
      def update_productions_details
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        @updateproductiondetail = SpcReceiptsDetail.find_by(id: params[:id], warehouse: @userWarehouse)
        @codigo = SkuMaster.all
        
        if @updateproductiondetail.nil?
          flash[:danger] = "Record not found"
          productions_details_path(production_identifier: update_productions_details_params[:production_identifier])
        else
          @update_productions_details_params = {
            spc: @updateproductiondetail.spc,
            lineno: @updateproductiondetail.lineno,
            codigo: @updateproductiondetail.codigo,
            pallet: @updateproductiondetail.pallet,
            lot: @updateproductiondetail.lot,
            lbo: @updateproductiondetail.lbo,
            quantity: @updateproductiondetail.quantity,
            uom: @updateproductiondetail.uom,
            production_identifier: @updateproductiondetail.production_identifier,
            receipt_type: @updateproductiondetail.receipt_type,
            recording_timestamp: @updateproductiondetail.recording_timestamp,
            receipt_id: @updateproductiondetail.receipt_id,
            id: @updateproductiondetail.id
          }
        end
      end


      def delete_productions_details
        @id = params[:id]
  
        if @id.present?
          @productionDetails = SpcReceiptsDetail.find_by(id: @id)
          if @productionDetails
            @productionidentifier = @productionDetails.production_identifier
            @result = ActiveRecord::Base.connection.execute("select spcwms.delete_production_details('#{@id}');")
  
            if @result[0]['delete_production_details'] == 'DELETED'
              flash[:success] = @result[0]['delete_production_details']
              redirect_to productions_details_path(production_identifier: @productionidentifier)
            else
              flash[:danger] = @result[0]['delete_production_details']
              redirect_to productions_details_path(production_identifier: @productionidentifier)
            end
          else
            flash[:danger] = "Receipt detail not found."
            redirect_to productions_details_path(id: params[:id])  
          end  
        else
          SystemLog.create(:procedure_name => 'productions_controller', :log_message => "Could not delete production details due to id variable not present: #{@id}")
          flash[:danger] = "Unable to delete selected receipt. Please contact support."
          redirect_to productions_details_path(id: params[:id])
        end
      end

    private

      def update_productions_details_params
        params.require(:spc_receipts_detail).permit(   
        :spc,
        :lineno,
        :codigo,
        :pallet,
        :lot,
        :lbo,
        :quantity,
        :uom,
        :production_identifier,
        :recording_timestamp,
        :id
        ).merge(codigo: params[:codigo]).merge(uom: params[:uom])
      end

      def selection_or_null(value)
        value.nil? || value.strip.empty? ? 'NULL' : "#{value}"
      end

end
