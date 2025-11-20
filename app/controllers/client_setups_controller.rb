class ClientSetupsController < ApplicationController
  before_action :last_sign_in

  def new
    @client = ClientSetup.new
  end

  def create
    ClientSetup.delete_all
    @client = ClientSetup.create(client_params)

    respond_to do |format|
      if @client.save(client_params)

          format.html { redirect_to supports_path, notice: 'Client successfully updated.' }
          format.json { render :show, status: :ok, location: @client, notice: 'Client successfully updated.'}
          format.js { render inline: 'location.reload();'}

          User.update_all(:company => @client.company)

        else
        format.html { render :edit }
        format.json { render json: @client.errors, status: :unprocessable_entity }
        end
       end

  end

  def edit
    @client = ClientSetup.find(params[:id])


  end


  def update
    @client = ClientSetup.find(params[:id])
    respond_to do |format|
      if @client.update(client_params)

          format.html { redirect_to refreshclient_path, notice: 'Client successfully updated.' }
          format.json { render :show, status: :ok, location: @client, notice: 'Client successfully updated.'}
          User.update_all(:company => @client.company)

        else
        format.html { render :edit }
        format.json { render json: @client.errors, status: :unprocessable_entity }
        end
       end



  end


  def smplbw_edit_client
    firmscode = params[:firmscode]

    @selectedClientByFirmcode = Form300referencedata.where(firmscode: firmscode).first
    SystemLog.create(:procedure_name => 'smplbw_edit_client', :log_message => "#{@selectedClientByFirmcode.city}")
  end


  def edit_client_validate
    permitted_params = params.permit(
      :firmscode,
      :facilityname,
      :irsidentificationnumber,
      :signatorytitle,
      :contactpersonlastname,
      :contactpersonfirstname,
      :contactpersonmiddleinitial,
      :telephonenumber,
      :streetaddress,
      :city,
      :state,
      :zipcode,
      :companyname
    )

    @selectedClientByFirmcode = Form300referencedata.find_by(firmscode: permitted_params[:firmscode])

    if @selectedClientByFirmcode.update(permitted_params)
      flash[:success] = "Updated data successfully!"
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem updating data: #{@selectedClientByFirmcode.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @selectedClientByFirmcode.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def editWarehouseData
    json_data = JSON.parse(request.body.read)
    array_data = json_data['arrayData']

    @editedWarehouseRecord = Warehousesetup.find_by(warehouse: array_data[4])

    if @editedWarehouseRecord.update(warehouse: array_data[0], firmscode: array_data[1], warehousename: array_data[2], capacity: array_data[3])
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @editedWarehouseRecord.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def editPartnumberData
    json_data = JSON.parse(request.body.read)
    array_data = json_data['arrayData']

    @editedPartnumberRecord = Partnumber.find_by(partnumber: array_data[2])

    if @editedPartnumberRecord.update(partnumber: array_data[0], uom: array_data[1])
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @editedPartnumberRecord.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def smplbw_new_submit
    permitted_params = params.permit(
      :firmscode,
      :facilityname,
      :irsidentificationnumber,
      :signatorytitle,
      :contactpersonlastname,
      :contactpersonfirstname,
      :contactpersonmiddleinitial,
      :telephonenumber,
      :streetaddress,
      :city,
      :state,
      :zipcode,
      :companyname
    )

    @addClientByFirmscode = Form300referencedata.new(permitted_params)

    if @addClientByFirmscode.save
      flash[:success] = "Updated data successfully!"
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem updating data: #{@addClientByFirmscode.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @addClientByFirmscode.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def smplbw_new_client
  end


  def editConversionsData
    json_data = JSON.parse(request.body.read)
    array_data = json_data['arrayData']

    @editedConversionRecord = Uomconversion.where(fromuom: array_data[3], touom: array_data[4]).update_all("fromuom = '#{array_data[0]}', touom = '#{array_data[1]}', conversionfactor = '#{array_data[2]}'")
  end


  def resetclient
    ClientSetup.delete_all
    flash[:info] = "Client has been reset."
    redirect_to refreshclient_path

  end

  def refresh
        respond_to do |format|
          format.js { render inline: 'location.reload();'}
        end
  end


  def add_new_warehousedata

  end

  def add_new_partnumber

  end

  def add_new_conversion

  end

  def add_new_firmscode

  end

  def addNewWarehouseData_final
    permitted_params = params.permit(
      :warehouse,
      :firmscode,
      :warehousename,
      :capacity
    )

    @newWarehouse = Warehousesetup.new(permitted_params)

    if @newWarehouse.save
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem adding data: #{@newWarehouse.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @newWarehouse.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def add_new_partnumber_final
    permitted_params = params.permit(
      :partnumber,
      :uom
    )

    @newPartnumber = Partnumber.new(permitted_params)

    if @newPartnumber.save
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem adding data: #{@newPartnumber.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @newPartnumber.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def add_new_conversion_final
    permitted_params = params.permit(
      :fromuom,
      :touom,
      :conversionfactor
    )

    @newConversion = Uomconversion.new(permitted_params)

    if @newConversion.save
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem adding data: #{@newConversion.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @newConversion.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  def add_new_firmscode_final
    permitted_params = params.permit(
      :warehouse,
      :firmscode,
      :warehousename,
      :capacity
    )

    @selectedWarehouse = Warehousesetup.new(permitted_params)

    if @selectedWarehouse.save
      respond_to do |format|
        format.json { render json: { status: 'success' } }
      end
    else
      flash[:danger] = "There was a problem adding data: #{@selectedWarehouse.errors.full_messages}"
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @selectedWarehouse.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  private

    def client_params
      params.require(:client_setup).permit(:company, :url)
    end

    def update_client_params
    end

end
