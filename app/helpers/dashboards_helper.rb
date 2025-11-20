module DashboardsHelper
  def get_research_inventory_details
    [{ field_name: 'spc', field_type: "string", display_name: "SPC" },
     { field_name: 'lineno', field_type: "number", display_name: "Line #" },
     { field_name: 'codigo', field_type: "string", display_name: "Codigo" },
     { field_name: 'pallet', field_type: "string", display_name: "Pallet" },
     { field_name: 'lot', field_type: "string", display_name: "Lot" },
     { field_name: 'lbo', field_type: "string", display_name: "LBO" },
     { field_name: 'quantity_remaining', field_type: "number", display_name: "Quantity Remaining" },
     { field_name: 'uom', field_type: "string", display_name: "UOM" },
     { field_name: 'production_identifier', field_type: "string", display_name: "Production Identifier" },
     { field_name: 'receipt_type', field_type: "string", display_name: "Type" },
     { field_name: 'recording_timestamp', field_type: "date", display_name: "Recorded" },
     { field_name: 'coo', field_type: "string", display_name: "COO" },
     { field_name: 'freezernum', field_type: "string", display_name: "Freezer #" },
     { field_name: 'racknum', field_type: "string", display_name: "Rack #" },
     { field_name: 'side', field_type: "string", display_name: "Side" },
     { field_name: 'location', field_type: "string", display_name: "Location" }
   ]
  end
end