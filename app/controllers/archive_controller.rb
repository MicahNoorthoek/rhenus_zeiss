class ArchiveController < ApplicationController
    before_action :authorizedScreens
    before_action :require_user
    #before_action :last_sign_in
  
    def index
      @selectedwarehouse = Selectedwarehouse.where(userid: current_user.id).pluck(:warehouse).first
  
      @user_tabs = UserWarehouseRole.where(user_email: current_user.email).where(warehouse: @selectedwarehouse).order(orderid: :asc).distinct.pluck(:user_tabs, :orderid)
      @available_warehouse = UserWarehouseRole.where(user_email: current_user.email).where(warehouse: @selectedwarehouse).distinct.pluck(:warehouse)
  
      @sr = SpcReceiptsArchive.where(warehouse: @selectedwarehouse).order(archived_date: :desc).ransack(params[:archivedreceipts], search_key: :archivedreceipts)
      @spc_receipt = @sr.result.paginate(page: params[:receipts_page], per_page: 20)
  
      @ss= SpcShipmentsArchive.where(warehouse: @selectedwarehouse).order(archived_date: :desc).ransack(params[:archivedshipments], search_key: :archivedshipments)
      @spc_ship = @ss.result.paginate(page: params[:ship_page], per_page: 20)
  
      @sp = SpcProductionArchive.where(warehouse: @selectedwarehouse).order(archived_date: :desc).ransack(params[:archivedproduction], search_key: :archivedproduction)
      @spc_prod = @sp.result.paginate(page: params[:prod_page], per_page: 20)
    end
  
  
    def receipts_details
      @spc = params[:spc]
      @archived_receipts_details = SpcReceiptsDetailsArchive.where(spc: @spc).where(receipt_type: "RECEIPT").order(id: :desc)
      render partial: "archive/receipts_details"
    end
  
  
    def production_details
      @prod_id = params[:production_identifier]
      @archived_production_details = SpcReceiptsDetailsArchive.where(production_identifier: @prod_id).where(receipt_type: "PRODUCTION").order(id: :desc)
      render partial: "archive/production_details"
    end
  
  
    def shipments_details
      @clientpo = params[:clientpo]
      @archived_shipments_details = SpcShipmentsDetailsArchive.where(clientpo: @clientpo).order(id: :desc)
      render partial: "archive/shipments_details"
    end
  
  end
  