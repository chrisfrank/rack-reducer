class ArtistRepository < Hanami::Repository
  def reduce(params)
    Rack::Reducer.call(
      params,
      dataset: artists.dataset,
      filters: SEQUEL_REDUCER[:filters],
    )
  end
end
