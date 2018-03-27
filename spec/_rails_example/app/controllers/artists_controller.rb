class ArtistsController < ApplicationController
  # GET /artists
  def index
    @artists = RailsExample::Artist.reduce(params)

    render json: @artists
  end
end
