class ArtistRepository < Hanami::Repository
  def query
    { dataset: artists.dataset, filters: SEQUEL_QUERY[:filters] }
  end

  def reduce(params)
    Rack::Reducer.call(params, query)
  end
end
