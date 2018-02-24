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
    end
  end
end
