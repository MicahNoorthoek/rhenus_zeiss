class VerifiedUser < ApplicationRecord
#self.table_name_prefix = 'spcwms.'
  validates_uniqueness_of :email, :message=>"{{value}} already exists."
end
