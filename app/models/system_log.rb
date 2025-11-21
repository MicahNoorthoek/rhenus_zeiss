class SystemLog < ApplicationRecord
 self.table_name = 'system_log'
 
 def self.ransackable_attributes(auth_object = nil)
    ["log_date", "log_message", "logid", "procedure_name"]
  end
end

#class SystemLog < ApplicationRecord
#  self.table_name = 'smplftz.system_log'
#end
