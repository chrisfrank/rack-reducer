require_relative '../../../../lib/hanami_example'

module Web::Controllers::Artists
  class Index
    include Web::Action
    expose :artists

    def call(params)
      @artists = ArtistRepository.new.reduce(params).all
      self.body = @artists.to_json
    end
  end
end
