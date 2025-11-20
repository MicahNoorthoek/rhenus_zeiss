class SpcShipment < ApplicationRecord
    #   self.table_name = 'spcwms.spc_shipments'

    def self.ransackable_attributes(auth_object = nil)
    ["cartons10lb", "cartons30lb", "cartons5lb", "client", "clientpo", "recording_timestamp", "releasedate", "warehouse"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end