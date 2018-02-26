module Rack
  class Reducer
    module Errors
      class Uncallable < StandardError
        def message
          "all filters must respond_to `call`. Try a lambda or proc"
        end
      end

      class Unreducable < StandardError
        def message
          "args[:filters] must respond_to `reduce`. Try an array or hash."
        end
      end

      class Unfilterable < StandardError
        def message
          "Pass a Rack-compatible :params => hash to Rack::Reducer.call()"
        end
      end
    end
  end
end
