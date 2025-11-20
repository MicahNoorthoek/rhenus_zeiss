class FiltersController < ApplicationController
  def prepare_filter_fields
    filters = params[params[:scope]]
    filters[:field_value] = filters[:field_value].to_s.gsub(/['"]/, '')

    respond_to do |format|
      format.turbo_stream
    end
  end


  def create_filter_form
  end
end