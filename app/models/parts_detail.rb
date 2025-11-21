class PartsDetail < ApplicationRecord
  self.table_name = 'parts_details'

  def self.ransackable_attributes(auth_object = nil)
    ["by_bal", "comments", "condition_id", "part_number", "pftz_bal", "status"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
