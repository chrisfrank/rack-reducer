require_relative '../../../../lib/hanami_example'

module Web::Controllers::Artists
  class Index
    include Web::Action

    def call(params)
      @artists = ArtistRepository.new.reduce(params).to_a
      self.body = @artists.to_json
    end
  end
end
