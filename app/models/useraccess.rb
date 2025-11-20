class Useraccess < ApplicationRecord
  self.table_name = 'spcwms.useraccess'
  #alias_attribute :id, :discrepancyid
  #self.primary_key = 'discrepancyid'

  def self.ransackable_attributes(auth_object = nil)
    ["email", "warehouse"]
  end
end
