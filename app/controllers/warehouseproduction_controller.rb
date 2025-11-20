class WarehouseproductionController < ApplicationController
    before_action :require_user
    #before_action :last_sign_in
    before_action :authorizedScreens

    def new
        begin
	  production_identifier = new_production_params[:production_identifier].strip
          if production_identifier.match?(/[!@$%^&*)(}{\]\[~`\/]/)
            flash[:danger] = "Production Identifier contains invalid characters."
            session[:WPCERROR] = 'ERROR'
            session[:wpc_params] = new_production_params
            redirect_to warehouse_production_path and return
          end

          existing_production = SpcProduction.find_by(production_identifier: new_production_params[:production_identifier], warehouse: new_production_params[:warehouse])
          archived_existing_production = SpcProductionArchive.find_by(production_identifier: new_production_params[:production_identifier], warehouse: new_production_params[:warehouse])

          if existing_production || archived_existing_production
            if archived_existing_production
              flash[:danger] = "An archived production already exists with production identifier: #{new_production_params[:production_identifier]}"
            else
              flash[:danger] = "Production already exists with production identifier: #{new_production_params[:production_identifier]}"
            end
            session[:WPCERROR] = 'ERROR'
            session[:wpc_params] = new_production_params
            redirect_to warehouse_production_path
          else

            @production = SpcProduction.create(new_production_params)
            if @production#.save(new_production_params)
              flash[:success] = "Saved Successfully"
              redirect_to warehouse_production_path
            else
              flash[:danger] = "There was a problem"
              redirect_to warehouse_production_path
            end
          end
          
        rescue => e
          SystemLog.create(:procedure_name => 'warehouse_production_controller', :log_message => "Error: #{e}")
          session[:WPCERROR] = 'ERROR'
          session[:wpc_params] = new_production_params
  
          flash[:danger] = "Unknown error: Check system logs"
          redirect_to warehouse_production_path
        end
      end


      def update
        begin
          @result = ActiveRecord::Base.connection.execute("select spcwms.update_production('#{update_production_params[:production_identifier]}', '#{update_production_params[:releasedate]}', '#{update_production_params[:process_type]}');")
          if @result.first['update_production'] == 'RECORDED'
            flash[:success] = "Production updated successfully"
            redirect_to warehouse_production_path
          else
            flash[:danger] = @result.first['update_production']
            redirect_to warehouse_production_path
          end
    
        rescue => e
          SystemLog.create(procedure_name: 'warehouseproduction_controller', log_message: "Error: #{e}")
          flash[:danger] = "An unknown error occurred. Check system logs."
  
          redirect_to warehouse_production_path
        end
      end
  
  
      def update_production
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        @process = ProcessType.where(warehouse: @userWarehouse).all
        @updateproduction = SpcProduction.find_by(production_identifier: params[:production_identifier], warehouse: @userWarehouse)
        
        if @updateproduction.nil?
          flash[:danger] = "Record not found"
          redirect_to warehouse_production_path
        else
          @update_production_params = {
            production_identifier: @updateproduction.production_identifier,
            releasedate: @updateproduction.releasedate,
            process_type: @updateproduction.process_type
          }
        end
      end


      def delete_production
        @production_identifier = params[:production_identifier]
  
        if @production_identifier.present?
          @result = ActiveRecord::Base.connection.execute("select spcwms.delete_production('#{@production_identifier}');")
  
          if @result[0]['delete_production'] == 'DELETED'
            flash[:success] = @result[0]['delete_production']
            redirect_to warehouse_production_path
          else
            flash[:danger] = @result[0]['delete_production']
            redirect_to warehouse_production_path
          end
        else
          SystemLog.create(:procedure_name => 'warehouse_production_controller', :log_message => "Could not delete production due to Production Identifier variable not present: #{@production_identifier}")
          flash[:danger] = "Unable to delete selected production. Please contact support."
          redirect_to warehouse_production_path
        end
      end


      def archive_production
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        @prod_id = params[:production_identifier]
        @results = SpcProduction.where(warehouse: @userWarehouse).where(production_identifier: @prod_id)
        
        if @results.present?
          ActiveRecord::Base.connection.execute("CALL archive_production('#{@prod_id}', '#{@userWarehouse}');")

          @message = ProcedureMessage.find_by(procedureid: 6)
          if @message.message.present?
            if @message.message.include?('Success')
              flash[:success] = @message.message
              redirect_to warehouse_production_path
            else
              flash[:warning] = @message.message
              redirect_to warehouse_production_path
            end
          else
            flash[:warning] = "Could not get response from archive procedure"
            redirect_to warehouse_production_path
          end
        else
          @archivedResults = SpcProductionArchive.where(warehouse: @userWarehouse).where(production_identifier: @prod_id)
          if @archivedResults.present?
            flash[:warning] = "Production Identifier: #{@prod_id} Production has already been archived"
            redirect_to warehouse_production_path
          else
            flash[:warning] = "Found no production to archive. SPC: #{@prod_id}"
            redirect_to warehouse_production_path
          end
        end
      end
 

      private

      def new_production_params
        params.require('/warehouse_production').permit(
          :production_identifier,  
          :releasedate  
        ).merge(process_type: params[:process_type]).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def produce_production_params
        params.require('/produce_production').permit(
          :spc,
          :pallet,
          :lot,
          :lbo,
          :quantity_remaining,
          :uom 
        ).merge(codigo: params[:codigo]).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def update_production_params
        params.require(:spc_production).permit(
          :production_identifier,  
          :releasedate,
          :process_type
        ).merge(process_type: params[:process_type])  
        #).merge(process_type: params[:process_type]).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end


end    
