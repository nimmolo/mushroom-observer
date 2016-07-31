class Query::ObservationAtLocation < Query::Observation
  def parameter_declarations
    super.merge(
      location: Location
    )
  end

  def initialize_flavor
    location = find_cached_parameter_instance(Location, :location)
    title_args[:location] = location.display_name
    self.where << "locations.location_id = '#{location.id}'"
    params[:by] ||= "name"
    super
  end
end