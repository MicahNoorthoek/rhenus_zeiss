class WarehousewithdrawalsController < ApplicationController
    before_action :require_user
    #before_action :last_sign_in
    before_action :authorizedScreens

    def new
      begin
	      clientpo = new_withdrawal_params[:clientpo].strip
        if clientpo.match?(/[!@$%^&*)(}{\]\[~`\/]/)
          flash[:danger] = "Client PO contains invalid characters."
          session[:ERROR] = 'ERROR'
          session[:wwc_params] = new_withdrawal_params
          redirect_to warehouse_withdrawals_path and return
        end

        existing_shipment = SpcShipment.find_by(clientpo: new_withdrawal_params[:clientpo], warehouse: new_withdrawal_params[:warehouse])
        archive_existing_shipment = SpcShipmentsArchive.find_by(clientpo: new_withdrawal_params[:clientpo], warehouse: new_withdrawal_params[:warehouse])

        if existing_shipment || archive_existing_shipment
          if archive_existing_shipment
            flash[:danger] = "An archived shipment already exists for client PO: #{new_withdrawal_params[:clientpo]}"
          else
            flash[:danger] = "Shipment already exists for client PO: #{new_withdrawal_params[:clientpo]}"
          end
          session[:ERROR] = 'ERROR'
          session[:wwc_params] = new_withdrawal_params
          redirect_to warehouse_withdrawals_path
        else
          defaulted_params = default_carton_params(new_withdrawal_params)

          @shipments = SpcShipment.create(defaulted_params)
          if @shipments#.save(defaulted_params)
            flash[:success] = "Saved Successfully"
            redirect_to warehouse_withdrawals_path
          else
            flash[:danger] = "There was a problem saving the shipment"
            redirect_to warehouse_withdrawals_path
          end
        end  
        
      rescue => e
        SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "Error: #{e}")
        session[:ERROR] = 'ERROR'
        session[:wwc_params] = defaulted_params

        flash[:danger] = "Unknown error: Check system logs"
        redirect_to warehouse_withdrawals_path
      end
    end

    

    def update
      begin
        SystemLog.create(procedure_name: 'warehousewithdrawals_controller', log_message: "params: #{update_shipments_params}")
        @result = ActiveRecord::Base.connection.execute("select spcwms.update_shipments(
          '#{update_shipments_params[:releasedate]}',
          '#{placeholder_cleanup(update_shipments_params[:client])}', 
          '#{update_shipments_params[:clientpo]}', 
          #{selection_or_null(update_shipments_params[:cartons30lb])}, 
          #{selection_or_null(update_shipments_params[:cartons10lb])}, 
          #{selection_or_null(update_shipments_params[:cartons5lb])} 
        );")

        if @result.first['update_shipments'] == 'RECORDED'
          flash[:success] = "Shipment updated successfully"
          redirect_to warehouse_withdrawals_path
        else
          flash[:danger] = @result.first['update_shipments']
          redirect_to update_shipments_path(id: update_shipments_params[:clientpo])
        end
  
      rescue => e
        SystemLog.create(procedure_name: 'warehousewithdrawals_controller', log_message: "Error: #{e}")
        flash[:danger] = "An unknown error occurred. Check system logs."

        redirect_to warehouse_withdrawals_path
      end
    end


    def update_shipments
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @updateshipments = SpcShipment.find_by(clientpo: params[:clientpo], warehouse: @userWarehouse)
      @client = Client.all
      
      if @updateshipments.nil?
        flash[:danger] = "Record not found"
        warehouse_withdrawals_path
      else
        @update_shipments_params = {
          releasedate: @updateshipments.releasedate,
          client: @updateshipments.client,
          clientpo: @updateshipments.clientpo,
          cartons30lb: @updateshipments.cartons30lb,
          cartons10lb: @updateshipments.cartons10lb,
          cartons5lb: @updateshipments.cartons5lb
        }
      end
    end


    def delete_shipments
      @clientpo = params[:clientpo]

      if @clientpo.present?
        @result = ActiveRecord::Base.connection.execute("select spcwms.delete_shipment('#{@clientpo}');")

        if @result[0]['delete_shipment'] == 'DELETED'
          flash[:success] = @result[0]['delete_shipment']
          redirect_to warehouse_withdrawals_path
        else
          flash[:danger] = @result[0]['delete_shipment']
          redirect_to warehouse_withdrawals_path
        end
      else
        SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "Could not delete shipment due to sales_id variable not present: #{@clientpo}")
        flash[:danger] = "Unable to delete selected shipment. Please contact support."
        redirect_to warehouse_withdrawals_path
      end
      
    end


    def select_criteria
      session[:selectedReceipts] = nil
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @current_recipientValue = params[:clientpoORprodid]
      @from = params[:from]
      
      @availableSPC = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where('quantity_remaining > ?', 0).pluck(:spc).uniq.sort
      @availableClientpo = SpcReceiptsArchive.where(warehouse: @userWarehouse).where(spc: @availableSPC).pluck(:clientpo).uniq.sort
      @availableLBO = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where('quantity_remaining > ?', 0).pluck(:lbo).uniq.sort
      @availablePallet = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where('quantity_remaining > ?', 0).pluck(:pallet).uniq.sort
      @availableSKU = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where('quantity_remaining > ?', 0).pluck(:codigo).uniq.sort

      session[:assignmentRecipient] = params[:clientpoORprodid] #who to assign this to. If shipments, then by clientpo, if production, then by production_identifier
      session[:criteria_from] = params[:from] #coming from production(will equal 'PROD')

      render partial: "warehousewithdrawals/select_criteria", layout: false

      #respond_to do |format|
      #  format.html { render partial: "warehousewithdrawals/select_criteria", layout: false }
      #end


    end


    def select_shipments_details
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      current_userid = current_user.id
      @current_recipientValue = params[:current_recipientValue]
      @from = params[:from]

      if session[:addedProductforProduction] != 'ADDMORE'
        if params[:select_shipments_details_page].nil?
          if params[:select_criteria].present?
            selected_values = []

            params[:select_criteria].each do |index, criteria|
              if criteria.present?
                selected_values << criteria
              end
            end

            if selected_values.any?
              @spcSelection = placeholder_cleanup(params[:select_criteria][:criteriaSpc])
              @clientpoSelection = placeholder_cleanup(params[:select_criteria][:criteriaClientPO])
              @palletSelection = placeholder_cleanup(params[:select_criteria][:criteriaPallet])
              @lboSelection = placeholder_cleanup(params[:select_criteria][:criteriaLbo])
              @skuSelection = placeholder_cleanup(params[:select_criteria][:criteriaSku])
            else
              flash[:warning] = "No criteria were selected"
              if @from == 'PROD'
                redirect_to warehouse_production_path
              elsif @from == 'SHIP'
                redirect_to warehouse_withdrawals_path
              else
                redirect_to dashboard_path
              end
            end
          end

          if params[:select_criteria].present? || params[:clientpo].present? #where are params[:clientpo] coming from and how is it used?
            ActiveRecord::Base.connection.execute(
                "CALL select_receipts(
                  #{current_userid},
                  '#{@clientpoSelection}',
                  '#{@spcSelection}',
                  '#{@skuSelection}',
                  '#{@lboSelection}',
                  '#{@palletSelection}'
                )"
              )

            @message = ProcedureMessage.find_by(procedureid: 4)
            if @message.message.present?
              @procMessage = @message.message
            end

            @receiptdetails = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).order(id: :asc).paginate(page: params[:select_shipments_details_page], per_page: 30)
            @amtOfReceipt = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).count
          else
            flash[:warning] = "Could not get parameters to select by criteria" 
            if @from == 'PROD'
              redirect_to warehouse_production_path
            elsif @from == 'SHIP'
              redirect_to warehouse_withdrawals_path
            else
              redirect_to dashboard_path
            end
          end
        else
          
          @current_recipientValue = params[:current_recipientValue]
          @from = params[:from]

          #@selected_receipts = (params[:selected_receipts] || []).map(&:to_i)
          #SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "ID's: #{@selected_receipts}")
          #@selectedQty = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where(id: @selected_receipts).sum(:quantity_remaining)

          SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "selectedQty: #{@selectedQty}")
          @receiptdetails = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).order(id: :asc).paginate(page: params[:select_shipments_details_page], per_page: 30)
          @amtOfReceipt = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).count
        end

      else #add more
        session[:addedProductforProduction] = nil 
        @receiptdetails = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).order(id: :asc).paginate(page: params[:select_shipments_details_page], per_page: 30)
        @amtOfReceipt = Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).count
      end
    end


    def process_selected_receipts #this is for both shipments and production
      session[:addedProductforProduction] = nil 
      #Rails.logger.debug "Params received: #{params.inspect}"

      @current_recipientValue = params[:current_recipientValue]#session[:assignmentRecipient]#this is the clientpo or production_identifier initially set by the link to select criteria from either prod or ship
      @from = params[:from]#session[:criteria_from] #this is the source of the selection, either production or shipments; determines flow of method set by same process as above

      
      # params[:selected_receipts] comes either directly from the select_shipments_details page or from the produce_part page that is shown
      #     when a user, coming from prod, clicks the 'Assign to Production' button and adds the new product info
      if params[:selected_receipts].present? && params[:current_recipientValue].present? # ensures that user made at least one selection and that the recipient(this is either clientpo or production_identifier) is set
        @clientpoSelection = params[:current_recipientValue] || ''
        current_userid = current_user.id
  
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        if @from == 'PROD'
          @fromid = params[:fromid]

          @selectedReceiptDetailsforProduction = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where(id: @fromid).all
          ActiveRecord::Base.connection.execute(
            "CALL assign_receipts2production(
              #{current_userid}, 
              '#{params[:selected_receipts][:spc]}', 
              '#{@current_recipientValue}',
              #{@fromid},
              '#{params[:codigo]}',
              '#{params[:selected_receipts][:pallet]}', 
              '#{params[:selected_receipts][:lot]}', 
              '#{params[:selected_receipts][:lbo]}',
              1,
              #{params[:selected_receipts][:quantity]},
              '#{Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first}', 
              '#{@selectedReceiptDetailsforProduction.first.coo}', 
              '#{@selectedReceiptDetailsforProduction.first.uom}',
              '#{params[:selected_receipts][:uom]}',
              '#{params[:selected_receipts][:freezernum]}', 
              '#{params[:selected_receipts][:racknum]}', 
              '#{params[:selected_receipts][:side]}',
              '#{params[:selected_receipts][:location]}',
              '#{current_user.username}'
            )"
          )

          @message = ProcedureMessage.find_by(procedureid: 7)
          if @message.message.present?
            if @message.message.include?('Success')
              if Mergedresults4linking.where(warehouse: @userWarehouse).where(userid: current_userid).count > 0
                session[:assignmentRecipient]=nil
                session[:criteria_from]=nil

                flash[:success] = @message.message
                session[:addedProductforProduction] = 'ADDMORE' #this session variable is used in select_shipments_details to control whether to rerun the select_receipts procedure
                redirect_to select_shipments_details_path(clientpo: @current_recipientValue, from: @from, current_recipientValue: @current_recipientValue)#PROD DETAILS
              else
                session[:assignmentRecipient]=nil
                session[:criteria_from]=nil
                flash[:success] = @message.message + " - No more receipts to assign"
                SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "no more receipts to assign for production: #{@current_recipientValue}")
                redirect_to productions_details_path(production_identifier: @current_recipientValue)#PROD DETAILS
              end
            else
              flash[:warning] = @message.message
              redirect_to productions_details_path(production_identifier: @current_recipientValue)#PROD DETAILS
            end
          else
            flash[:warning] = "Could not get response from assign procedure"
            redirect_to warehouse_production_path#PROD DETAILS
          end

        elsif @from == 'SHIP'
          
          @selectedIds ||= []

          selected_receipts = (params[:selected_receipts][0].is_a?(String) ? params[:selected_receipts][0].split(',') : params[:selected_receipts]) || []
          selected_receipts = selected_receipts.map(&:to_i)

          Rails.logger.debug "Selected Receipts: #{selected_receipts}"

          selected_receipts.each do |receipt_id|
            if receipt_id.present?
              @selectedIds << receipt_id.to_i
            end
          end

          if selected_receipts.any?

            selected_receipts.each do |receipt_id|
              @qtyObject = JSON.parse(params[:selected_receipts_data] || '{}')
              SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "id, qty object: #{@qtyObject}")

              @selectedReceipt = SpcReceiptsDetailsArchive.where(warehouse: @userWarehouse).where(id: receipt_id).all
              selected_qty = @qtyObject[receipt_id.to_s].present? ? @qtyObject[receipt_id.to_s] : @selectedReceipt.first.quantity_remaining

              ActiveRecord::Base.connection.execute(
                "CALL assign_receipts2shipment(
                  #{current_userid}, 
                  #{receipt_id}, 
                  #{selected_qty},
                  '#{@userWarehouse}',
                  '#{@clientpoSelection}'
                )"
              )
  
            end

            @message = ProcedureMessage.find_by(procedureid: 5)
            if @message.message.present?
              if @message.message.include?('Success')
                session[:assignmentRecipient]=nil
                session[:criteria_from]=nil
                flash[:success] = @message.message
                redirect_to shipments_details_path(clientpo: @clientpoSelection)
              else
                flash[:warning] = @message.message
                redirect_to warehouse_withdrawals_path
              end
            else
              flash[:warning] = "Could not get response from assign procedure"
              redirect_to warehouse_withdrawals_path
            end
          else
            flash[:warning] = "You must select at least one receipt to link to shipments."
            redirect_to warehouse_withdrawals_path
          end
        else
          flash[:warning] = "Tried to assign receipts to unknown - neither shipments nor production"
          redirect_to dashboard_path
        end
        
      else
        flash[:warning] = "No receipts were selected or params are missing."
        if @from == 'PROD'
          redirect_to warehouse_production_path
        elsif @from == 'SHIP'
          redirect_to warehouse_withdrawals_path
        else
          redirect_to dashboard_path
        end
      end
    end


    def archive_shipment
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      @clientpo = params[:clientpo]
      @results = SpcShipment.where(clientpo: @clientpo).where(warehouse: @userWarehouse)
      
      if @results.present?
        ActiveRecord::Base.connection.execute("CALL archive_shipment('#{@clientpo}', '#{@userWarehouse}');")

        @message = ProcedureMessage.find_by(procedureid: 2)
        if @message.message.present?
          if @message.message.include?('Success')
            flash[:success] = @message.message
            redirect_to warehouse_withdrawals_path
          else
            flash[:warning] = @message.message
            redirect_to warehouse_withdrawals_path
          end
        else
          flash[:warning] = "Could not get response from archive procedure"
          redirect_to warehouse_withdrawals_path
        end
      else
        @archivedResults = SpcShipmentsArchive.where(clientpo: @clientpo).where(warehouse: @userWarehouse).all
        if @archivedResults.present?
          flash[:warning] = "Client PO: #{@clientpo} shipment has already been archived"
          redirect_to warehouse_withdrawals_path
        else
          flash[:warning] = "Found no shipment to archive. Client PO: #{@clientpo}"
          redirect_to warehouse_withdrawals_path
        end
      end
    end


    def produce_part
      @current_recipientValue = params[:current_recipientValue]#session[:assignmentRecipient]
      @from = params[:from]

      @id = params[:id]
      @receiptArchiveDetails = SpcReceiptsDetailsArchive.find_by(id: @id)
      @codigo = SkuMaster.all
      SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "Result: #{@receiptArchiveDetails.id}")

      render partial: "warehousewithdrawals/produce_part", layout: false
      #render partial: "warehousewithdrawals/produce_part", status: :unprocessable_entity, layout: false
      #render turbo_stream: turbo_stream.replace("produce_part_modal", partial: "warehousewithdrawals/produce_part")
    end


    def positive_release_get_date
      respond_to do |format|
        format.js { render 'warehousewithdrawals/positive_release_get_date' }
        format.html { render partial: 'warehousewithdrawals/positive_release_report' }
      end
    end

    def set_up_positive_release_report
      begin
          session[:positivereleasereports] = ''
          session[:releasedate] = ''
          session[:clientpo] = ''
          session[:client] = ''

          current_userid = current_user.id
          @release_date = positive_release_report_params[:releasedate]
          @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
          @clientpo = positive_release_report_params[:clientpo]
          @client = positive_release_report_params[:client]

          @pos_rel_result = ActiveRecord::Base.connection.execute("select spcwms.create_positive_release_report_sh(
                #{current_userid},
                '#{@userWarehouse}',
                '#{@clientpo}'
                );")
                
          if @pos_rel_result.present?
            report_status = @pos_rel_result[0]['create_positive_release_report'] || @pos_rel_result[0].values.first
            SystemLog.create(:procedure_name => 'warehousewithdrawals_controller', :log_message => "Report Status: #{report_status}")

            if report_status == 'GENERATED'
              session[:positivereleasereports] = 'GENERATED'
              session[:releasedate] = @release_date
              session[:clientpo] = @clientpo
              session[:client] = @client
              #flash[:success] = "Positive Release Report generated for #{@clientpo}"
              
              if params[:commit] == 'Download Excel' || params[:commit] == 'Excel'
                redirect_to generate_positive_release_report_path(format: :xlsx)
              else
                redirect_to generate_positive_release_report_path
              end

            else 
              flash[:danger] = "Error in generating Positive Release Report"
              redirect_to warehouse_withdrawals_path
              
            end

          else
            flash[:danger] = "No result returned from the SQL function"
            redirect_to warehouse_withdrawals_path
          end  

      rescue => e
          session[:positivereleasereports] = ''
          session[:releasedate] = ''
          SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "Error: #{e}")
          flash[:danger] = "Unknown error: Check system logs"
          redirect_to warehouse_withdrawals_path
      end
    end


    def generate_positive_release_report
      begin
        @release_date = session[:releasedate]   
        @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
        @clientpo = session[:clientpo]
        @client = session[:client]
        @total_cases = SpcShipmentsPositiveRelease.where(warehouse: @userWarehouse).where(releasedate: @release_date).where(clientpo: @clientpo).sum(:quantity)

        SystemLog.create(:procedure_name => 'warehousewithdrawals_controller', :log_message => " Positive Release Report #{@clientpo}")

        @positive_release_report_data = ShipmentsPositivereleasereport.all


        respond_to do |format|
          format.xlsx do
          render xlsx:    "positive_release_report",        
                filename: "PositiveReleaseReport_#{@clientpo}.xlsx" 
          end
        
          format.html do
            pdf = render_to_string(pdf: "positive_release_report", 
              template: "warehousewithdrawals/positive_release_report", 
              formats: [:pdf, :html],
              layout: "pdf",
              orientation: 'Portrait',
              page_size: 'Letter',
              margin: {
                top: 5,
                bottom: 20,
                left:  2,
                right: 2
              })

          send_data pdf, type: 'application/pdf', disposition: 'attachment', filename: "PositiveReleaseReport_#{@clientpo}.pdf"
          SystemLog.create(:procedure_name => 'warehousewithdrawals_controller', :log_message => "Downloaded {PositiveReleaseReport}_#{@clientpo}.pdf")
          end
        end  

      rescue => e
        SystemLog.create(:procedure_name => 'warehousewithdrawals_controller', :log_message => "Positive Release Error: #{e}")
        flash[:danger] = "Unknown error: Check system logs"
        redirect_to warehouse_withdrawals_path
      end
    end  


    def new_client
      begin
        existing_client = Client.find_by(client: new_client_params[:client])
  
        if existing_client
            flash[:danger] = "Client already exists."    
            session[:WCERROR] = 'ERROR'
            session[:wc_params] = new_client_params
            redirect_to warehouse_withdrawals_path
        else
          @client = Client.create(new_client_params)
          if @client#.save(new_client_params)
            flash[:success] = "Saved Successfully"
          else
            flash[:danger] = "There was a problem saving new client"         
          end
          redirect_to warehouse_withdrawals_path
        end
                 
      rescue => e
        SystemLog.create(:procedure_name => 'warehouse_withdrawals_controller', :log_message => "Error: #{e}")
        session[:WCERROR] = 'ERROR'
        session[:wc_params] = new_client_params

        flash[:danger] = "Unknown error: Check system logs"
        redirect_to warehouse_withdrawals_path
      end
    end

    def warehouse_client_form
      @userWarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
      if session[:WCERROR] == 'ERROR'
        @client_params = session[:wc_params]
      else
        session[:wc_params] = ''
        session[:WCERROR] = ''
      end

      session[:wc_params] = ''
      session[:WCERROR] = ''

      @countries = CountriesOfOrigin.all
      Rails.logger.debug "Countries of Origin: #{@countries.inspect}"

    end

    private

      def new_withdrawal_params
        params.require('/warehouse_withdrawals').permit(
          :releasedate,
          :clientpo,
          :cartons30lb,
          :cartons10lb,
          :cartons5lb,
        ).merge(client: placeholder_cleanup(params[:client])).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def update_shipments_params
        params.require(:spc_shipment).permit(
          :releasedate,
          :clientpo,
          :cartons30lb,
          :cartons10lb,
          :cartons5lb
        ).merge(client: placeholder_cleanup(params[:client])).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def produce_production_params
        params.require('/selected_receipts').permit(
          :spc,
          :pallet,
          :lot,
          :lbo,
          :quantity_remaining,
          :uom 
        ).merge(codigo: params[:codigo]).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def selection_or_null(value)
        value.nil? || value.strip.empty? ? 'NULL' : "#{value}"
      end

      def placeholder_cleanup(value)
        value.nil? || value.strip.empty? || value.include?('Select') ? '' : "#{value}"
      end

      def default_carton_params(params)
        defaulted_params = params.dup
        carton_keys = [:cartons30lb, :cartons10lb, :cartons5lb]
      
        carton_keys.each do |key|
          defaulted_params[key] = 0 if defaulted_params[key].blank?
        end
      
        defaulted_params
      end

      def valid_date(value)
        current_date = Date.today
        release_date = Date.parse(value) rescue nil

        if release_date.nil? || release_date < current_date - 7 || release_date > current_date + 7
          return nil 
        end
      
        release_date  
      end
      
      def positive_release_report_params
        params.require('/set_up_positive_release_report').permit(
          :releasedate,
          :clientpo,
          :client
          ).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end

      def new_client_params
        params.require('/warehouse_clients').permit(
          :client,
          :country_of_origin
        ).merge(warehouse: Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first)
      end  

end
