class SpcShipmentsArchive < ApplicationRecord
    self.table_name = 'spcwms.spc_shipments_archive'

    def self.ransackable_attributes(auth_object = nil)
        column_names + (defined?(_ransackers) ? _ransackers.keys : [])
    end

    def self.ransackable_associations(auth_object = nil)
        reflect_on_all_associations.map { |a| a.name.to_s }
    end

end