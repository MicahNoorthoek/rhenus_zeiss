class ShipmentsController < ApplicationController
    before_action :authorizedScreens
    before_action :require_user
    #before_action :last_sign_in

    def shipments_details
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        if params[:clientpo].present?
            session[:assignmentRecipient] = params[:clientpo]
        end
        @shipmentDetails = SpcShipmentsDetail.where(warehouse: @userWarehouse).where(clientpo:session[:assignmentRecipient]).all.ransack(params[:details_page]).result.order(id: :desc).paginate(page: params[:details_page], per_page: 15)
        @qty = SpcShipmentsDetail.where(warehouse: @userWarehouse)
                      .where(clientpo:session[:assignmentRecipient])
                      .sum("CASE 
                              WHEN uom = 'CAS30' THEN quantity * 30
                              WHEN uom = 'CAS10' THEN quantity * 10
                              WHEN uom = 'CAS05' THEN quantity * 5
                              ELSE quantity
                            END")

        #@qty = SpcShipmentsDetail.where(clientpo:session[:assignmentRecipient]).sum(:quantity)
        @clientpo = session[:assignmentRecipient]
        @countries = CountriesOfOrigin.all
        @codigo = SkuMaster.all
    end


      def update
        begin

          error_messages = []

          spc = update_shipments_details_params[:spc].strip
          if spc.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "SPC contains invalid characters."
          end

          lbo = update_shipments_details_params[:lbo].strip
          if lbo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "LBO contains invalid characters."
          end
  
          pallet = update_shipments_details_params[:pallet].strip
          if pallet.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "Pallet contains invalid characters."
          end
  
          lot = update_shipments_details_params[:lot].strip
          if lot.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            error_messages << "Lot contains invalid characters."
          end
  
          if error_messages.any?
            flash[:danger] = error_messages.join(" ")
            session[:WRCERROR] = 'ERROR'
            session[:wrc_params] = update_shipments_details_params
            redirect_to shipments_details_path(clientpo: update_shipments_details_params[:clientpo]) and return
          end

          @result = ActiveRecord::Base.connection.execute("select spcwms.update_shipment_details(
          '#{update_shipments_details_params[:clientpo]}',
          '#{update_shipments_details_params[:spc]}', 
          #{selection_or_null(update_shipments_details_params[:lineno])}, 
          '#{update_shipments_details_params[:codigo]}', 
          '#{update_shipments_details_params[:pallet]}', 
          '#{update_shipments_details_params[:lot]}', 
          '#{update_shipments_details_params[:lbo]}', 
          '#{update_shipments_details_params[:quantity]}', 
          '#{update_shipments_details_params[:coo]}',
          '#{update_shipments_details_params[:id]}');
          ")
          if @result.first['update_shipment_details'] == 'RECORDED'
            flash[:success] = "Shipment details updated successfully"
            redirect_to shipments_details_path(clientpo: update_shipments_details_params[:clientpo])
          else
            flash[:danger] = @result.first['update_shipment_details']
            redirect_to update_shipments_details_path(id: update_shipments_details_params[:id])
          end
    
        rescue => e
          SystemLog.create(procedure_name: 'shipments_controller', log_message: "Error: #{e}")
          flash[:danger] = "An unknown error occurred. Check system logs."
  
          redirect_to update_shipments_details_path(id: update_shipments_details_params[:id])
        end
      end
  
  
      def update_shipments_details
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        @updateshipmentdetail = SpcShipmentsDetail.find_by(id: params[:id], warehouse: @userWarehouse)
        @countries = CountriesOfOrigin.all
        @codigo = SkuMaster.all
        
        if @updateshipmentdetail.nil?
          flash[:danger] = "Record not found"
          redirect_to shipments_details_path(id: params[:id])
        else
          @update_shipments_details_params = {
            clientpo: @updateshipmentdetail.clientpo,
            spc: @updateshipmentdetail.spc,
            lineno: @updateshipmentdetail.lineno,
            codigo: @updateshipmentdetail.codigo,
            pallet: @updateshipmentdetail.pallet,
            lot: @updateshipmentdetail.lot,
            lbo: @updateshipmentdetail.lbo,
            quantity: @updateshipmentdetail.quantity,
            coo: @updateshipmentdetail.coo,
            id: @updateshipmentdetail.id
          }
        end
      end


      def delete_shipments_details
        @id = params[:id]
  
        if @id.present?
          @result = ActiveRecord::Base.connection.execute("select spcwms.delete_shipment_details('#{@id}');")
  
          if @result[0]['delete_shipment_details'] == 'DELETED'
            flash[:success] = @result[0]['delete_shipment_details']
            redirect_to shipments_details_path(id: params[:id])
          else
            flash[:danger] = @result[0]['delete_shipment_details']
            redirect_to shipments_details_path(id: params[:id])
          end
        else
          SystemLog.create(:procedure_name => 'shipments_controller', :log_message => "Could not delete shipment details due to id variable not present: #{@id}")
          flash[:danger] = "Unable to delete selected receipt. Please contact support."
          redirect_to shipments_details_path(id: params[:id])
        end
      end

    private
        def new_shipments_details_params
            params.require('/shipments_details').permit(
            :spc,
            :clientpo,
            :lineno,
            :pallet,
            :lot,
            :quantity,
            :lbo 
            ).merge(codigo: params[:codigo]).merge(coo: params[:coo]).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
        end

        def update_shipments_details_params
          params.require(:spc_shipments_detail).permit(
            :clientpo,    
            :spc,
            :lineno,
            :pallet,
            :lot,
            :lbo,
            :quantity,
            :id
          ).merge(codigo: params[:codigo]).merge(coo: params[:coo])
        end

        def placeholder_cleanup(value)
          value.nil? || value.strip.empty? || value.include?('Select') ? '' : "#{value}"
        end

        def selection_or_null(value)
          value.nil? || value.strip.empty? ? 'NULL' : "#{value}"
        end

end
