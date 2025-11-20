module ApplicationHelper
    def path_for_user_tab(user_tab)
        case user_tab.to_s.downcase
        when "receipts" then warehouse_receipts_path  
        when "shipments" then warehouse_withdrawals_path   
        when "production" then warehouse_production_path
        else root_path
        end
    end
end
  
  