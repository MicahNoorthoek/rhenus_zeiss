Rails.application.routes.draw do
  get "test/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # COMMENTED OUT BY MICAH NOORTHOEK 10/18/2023
  #require 'sidekiq/web'
  #require 'sidekiq-scheduler'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'welcome/index', to: 'welcome#index'
  root 'sessions#new'

  resources :users do
    collection { put :all_user_lock }
    member do
      patch :toggle_lock_status
      patch :toggle_auto_email
      patch :toggle_undo_shipment_lock
      patch :toggle_client_admin
    end
  end
  resources :discrepancies

  #resources :user_logs, :except => [:show]

  resources :verified_users
  resources :selected_emails


  get 'refresh_page', to: 'dashboards#refresh_page'



  get 'active'  => 'sessions#active'
  get 'timeout' => 'sessions#timeout'

  #mount Sidekiq::Web => '/sidekiq'

    get 'dashboards/:id/edit', to: 'dashboards#edit', as: 'dashboards_edit'

    get 'user_logs/index', to: 'user_logs#index', as: 'userlog'
    get 'user_logs/:id/userbody', to: 'user_logs#userbody', as: 'userbody'
    get 'user_logs/:id/userbodyadd', to: 'user_logs#userbodyadd', as: 'userbodyadd'
    get 'resolvedcurrent', to: 'user_logs#resolvedcurrent'
    get 'resolvedunread', to: 'user_logs#resolvedunread'
    get 'resolvedarchive', to: 'user_logs#resolvedarchive'
    get 'resolvedcurrentmsg', to: 'user_logs#resolvedcurrentmsg'
    get 'resolvedunreadmsg', to: 'user_logs#resolvedunreadmsg'
    get 'resolvedreadmsg', to: 'user_logs#resolvedreadmsg'
    get 'user_logs/:id/logdetails', to: 'user_logs#logdetails', as: 'logdetails'

    get 'user_logs/user_log_details', to: 'user_logs#user_log_details', as: 'user_log_details'
    get 'refresh_user_logs', to: 'user_logs#refresh'

  #discrepancies

  get 'discrepancies/index', to: 'discrepancies#index'
  get 'newdiscrepancies', to: 'discrepancies#new'

  get 'discrepancies/create', to: 'discrepancies#create'



  namespace :agent do
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    #delete 'logout', to: 'sessions#destroy'
    get 'logout', to: 'sessions#destroy'

    root "dashboard#index"
  end


  #login Sessions
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  get 'session_timeout', to: 'sessions#jstimeout'
  #delete 'logout', to: 'sessions#destroy'
  get 'logout', to: 'sessions#destroy'

  get 'createuser_38923489d8234k234', to: 'users#new'
  post 'users', to: 'users#create'
  get 'users/index', to: 'users#index'
  get 'users/show', to: 'users#show'
  delete 'users', to: 'users#destroy'

  get 'users/:id/edit', to: 'users#edit' , as: 'edit_users'
  post 'users/:id/edit', to: 'users#edit', as: 'update_users'
  get 'users/:id/show', to: 'users#show', as: 'show_users'

  #dashboard
  get 'dashboard', to: 'dashboards#index'

  get 'admin', to: 'admin#index'
  #get :supports, to: "admin#index"
  get 'authorize_user', to: 'admin#authorize_user'

  get 'passwords', to: 'passwords#create'
  get 'reset_password', to: 'passwords#edit', as: 'reset_password'
  put 'update_password', to: 'passwords#update_password', as: 'update_password'
  resources :passwords, only: [:create]

  #SPECIFICALLY CREATED ROUTES FOR NEW SMPLBW
  get 'warehouse_receipts', to: 'dashboards#warehouse_receipts_form'
  get 'warehouse_withdrawals', to: 'dashboards#warehouse_withdrawals_form'
  get 'variances', to: 'dashboards#variances_form'
  get 'report_balances', to: 'dashboards#report_balances_form'

   
  #get 'generate_form_300', to: 'system_forms#form_300_report_get_date'
  #post 'generate_form_300', to: 'system_forms#settingupreport'
  #get 'generate', to: 'system_forms#generate_form_300_report'
  #post 'settingupreport', to: 'system_forms#settingupreport'
  
    #SPECIFICALLY CREATED ROUTES FOR NEW SMPLFTZ
  get  'generate_annual', to: 'ftz_board_reports#ftz_board_report_get_year'
  post  'generate_annual', to: 'ftz_board_reports#set_up_annual_report'
  get  'generate_annual_report',  to: 'ftz_board_reports#generate_annual_report'
  post 'set_up_annual_report', to: 'ftz_board_reports#set_up_annual_report'
    # FTZ BOARD REPORT TEST AND PREVIEW
  get 'test_pdf', to: 'ftz_board_reports#test_pdf'
  get 'preview', to: 'ftz_board_reports#preview'

  get  'generate_annual_recon', to: 'annual_reconciliation_reports#annual_reconciliation_report_get_year'
  post  'generate_annual_recon', to: 'annual_reconciliation_reports#set_up_annual_recon_report'
  get  'generate_annual_recon_report',  to: 'annual_reconciliation_reports#generate_annual_recon_report'
  post 'set_up_annual_recon_report', to: 'annual_reconciliation_reports#set_up_annual_recon_report'


  #post 'warehouse_receipts', to: 'warehousereceipts#new'
  resources :warehouse_receipts, only: [:new, :create]
  post 'warehouse_withdrawals', to: 'warehousewithdrawals#new'
  post 'variances', to: 'variances#new'
  post 'report_balances', to: 'reported_balances#js_discrepancy_modal'

  get 'withdrawal_statement_report', to: 'pdfs#withdrawal_statement_report', format: 'pdf'
  get 'running_balance_report', to: 'pdfs#running_balance_report'

  get 'discrepancy_modal', to: 'reported_balances#js_discrepancy_modal'

  get 'depletednotreportedreceipts', to: 'warehousewithdrawals#depletednotreportedreceipts'

  get 'smplbw_users', to: 'admin#smplbw_users'
  get 'receipt_headers_view', to: 'admin#receipt_headers_view'
  get 'withdrawals_headers_view', to: 'admin#withdrawals_headers_view'
  get 'balances_view', to: 'admin#balances_view'
  get 'system_log', to: 'admin#system_log'
  get 'all_receipt_view', to: 'admin#all_receipt_view'
  get 'all_withdrawals_view', to: 'admin#all_withdrawals_view'
  get 'client_setup', to: 'admin#client_setup'

  get 'new_user_functions', to: 'admin#authorization'

  get 'on_close', to: 'sessions#on_close'

  get 'recalculate/:balancedate/balance',to: 'reported_balances#recalculate',as: 'recalculate_balance'
  get 'delete_balance',to: 'reported_balances#delete',as: 'delete_balance'

  get 'reprint_reports', to: 'warehousewithdrawals#regenerate_reports'
  #get 'reprint_reports', to: 'dashboards#thoughts'

  get 'references', to: 'references#index'
  post 'references', to: 'references#add', as: 'add_reference'
  get 'delete_reference',to: 'references#delete',as: 'delete_reference'

  get 'smplbw_firmscode_setup', to: 'admin#smplbw_firmscode_setup'
  get 'edit_user_firmscode', to: 'admin#edit_user_firmscode'
  get 'delete_user_firmscode', to: 'admin#delete_user_firmscode'

  get 'to_the_controller', to: 'nowhere#nowhere'

  post 'edit_user_firmscode', to: 'admin#add_edited_user_firmscode'
  get 'updating_selectedwarehouse_by_dropdown', to: 'dashboards#updating_selectedwarehouse_by_dropdown'

  get 'auditforgt1percentvariance_screen', to: 'variances#auditforgt1percentvariance_screen'

  get 'smplbw_edit_client', to: 'client_setups#smplbw_edit_client'
  post 'smplbw_edit_client', to: 'client_setups#edit_client_validate'

  get 'smplbw_add_client', to: 'client_setups#smplbw_new_client'
  post 'smplbw_add_client', to: 'client_setups#smplbw_new_submit'

  get 'admin_override', to: 'admin#admin_override'
  get 'log_user_out', to: 'admin#log_user_out'
  get 'checkifloggedout', to: 'admin#checkifloggedout'

  post 'editWarehouseData', to: 'client_setups#editWarehouseData'
  post 'editPartnumberData', to: 'client_setups#editPartnumberData'
  post 'editConversionsData', to: 'client_setups#editConversionsData'
  post 'smplbw_addnew_warehousedata', to: 'client_setups#addNewWarehouseData_final'
  post 'add_new_partnumber', to: 'client_setups#add_new_partnumber_final'
  post 'add_new_conversion', to: 'client_setups#add_new_conversion_final'
  post 'add_new_firmscode', to: 'client_setups#add_new_firmscode_final'

  get 'add_new_warehousedata', to: 'client_setups#add_new_warehousedata'
  get 'add_new_partnumber', to: 'client_setups#add_new_partnumber'
  get 'add_new_conversion', to: 'client_setups#add_new_conversion'
  get 'add_new_firmscode', to: 'client_setups#add_new_firmscode'
  
  get 'update_receipts', to: 'warehouse_receipts#update_receipts'
  post 'update_receipts', to: 'warehouse_receipts#update'

  get 'update_withdrawal', to: 'warehousewithdrawals#updatewithdrawal_view'
  post 'update_withdrawal', to: 'warehousewithdrawals#update'

  get 'verify_user', to: 'admin#verify_user'
  get 'forgot_password', to: 'admin#forgot_password'

  get 'view_stored_pdf', to: 'stored_pdf#view_stored_pdf'
  get 'view_latest_running_balance', to: 'stored_pdf#view_latest_running_balance'

  get 'delete_receipt', to: 'warehouse_receipts#delete_receipt'
  get 'delete_shipments', to: 'warehousewithdrawals#delete_shipments'
  get 'delete_production', to: 'warehouseproduction#delete_production'

  get 'verify_delete', to: 'delete_modal#delete'
  get 'lock_users', to: 'admin#lock_users'
  get 'finalize_lock_users', to: 'admin#finalize_lock_users'
  get 'testing', to: 'dashboards#testing'

  get 'receipts_details', to: 'receipts#receipts_details'
  post 'receipts_details', to: 'receipts#create'

  get 'update_receipts_details', to: 'receipts#update_receipts_details'
  post 'update_receipts_details', to: 'receipts#update'
  get 'delete_receipt_details', to: 'receipts#delete_receipt_details'

  get 'copy_shipments_details', to: 'warehousewithdrawals#copy_shipments_details'
  get 'select_shipments_details', to: 'warehousewithdrawals#select_shipments_details'
  post 'process_selected_receipts', to: 'warehousewithdrawals#process_selected_receipts'
  get 'shipments_details', to: 'shipments#shipments_details'
  post 'shipments_details', to: 'shipments#new'
  get 'update_shipments_details', to: 'shipments#update_shipments_details'
  post 'update_shipments_details', to: 'shipments#update'
  get 'delete_shipments_details', to: 'shipments#delete_shipments_details'

  get 'update_shipments', to: 'warehousewithdrawals#update_shipments'
  post 'update_shipments', to: 'warehousewithdrawals#update'

  get 'archive_shipment', to: 'warehousewithdrawals#archive_shipment'
  get 'archive_receipt', to: 'warehouse_receipts#archive_receipt'

  get 'select_criteria', to: 'warehousewithdrawals#select_criteria'
  post 'select_criteria', to: 'warehousewithdrawals#select_shipments_details'

  get 'warehouse_production', to: 'dashboards#warehouse_production_form'
  post 'warehouse_production', to: 'warehouseproduction#new'

  get 'update_production', to: 'warehouseproduction#update_production'
  post 'update_production', to: 'warehouseproduction#update'
  get 'archive_production', to: 'warehouseproduction#archive_production'
  get 'productions_details', to: 'productions#productions_details'
  get 'update_productions_details', to: 'productions#update_productions_details'
  post 'update_productions_details', to: 'productions#update'
  get 'delete_productions_details', to: 'productions#delete_productions_details'

  get 'produce_product', to: 'warehousewithdrawals#produce_part'
  post 'produce_product', to: 'warehousewithdrawals#process_selected_receipts'

  get 'warehouse_archive', to: 'archive#index'
  get 'archived_receipt_details', to: 'archive#receipts_details'
  get 'archived_production_details', to: 'archive#production_details'
  get 'archived_shipment_details', to: 'archive#shipments_details'

  get  'generate_positive_release', to: 'warehousewithdrawals#positive_release_get_date'
  post  'generate_positive_release', to: 'warehousewithdrawals#set_up_positive_release_report'
  get  'generate_positive_release_report',  to: 'warehousewithdrawals#generate_positive_release_report'
  post 'set_up_positive_release_report', to: 'warehousewithdrawals#set_up_positive_release_report'
  get 'generate_positive_release_report.xlsx', to: 'warehousewithdrawals#generate_positive_release_report', defaults: { format: 'xlsx' }

  get 'warehouse_clients', to: 'warehousewithdrawals#warehouse_clients_form'
  post 'warehouse_clients', to: 'warehousewithdrawals#new_client'

  get 'inventory_screen', to: 'dashboards#inventory_screen'
  post 'prepare_filter_fields', to: 'filters#prepare_filter_fields'
  post 'create_filter_form', to: 'filters#create_filter_form'

end
