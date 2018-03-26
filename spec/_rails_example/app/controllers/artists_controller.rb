class ArtistsController < ApplicationController
  before_action :set_artist, only: [:show, :update, :destroy]

  # GET /artists
  def index
    @artists = RailsExample::Artist.reduce(params)

    render json: @artists
  end

  # GET /artists/1
  def show
    render json: @artist
  end
end
