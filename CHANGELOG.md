# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0 (unreleased)

## Fixed
- Improve performance by ~30% for requests with empty params, and by ~5% for
  requests with full params.
- Simplify documentation.

### Added
- Create a changelog
- Encourage instantiating a reducer on boot via ::create, instead of
  instantiating a new reducer on every request.

### Removed
- Deprecate the "mixin-style" in favor of the new ::create API.
  To keep using Rack::Reducer in your models, create a Reducer constant.
    ```ruby
    class MyModel
      MyReducer = Rack::Reducer.create(dataset, *filter_functions)
    end
    MyModel::MyReducer.call(params)
    ```
- Deprecate mounting Rack::Reducer as middleware via `use Rack::Reducer`. It
  still works, but to mount middleware in a way that will remain compatible with
  v2, change `use Rack::Reducer` to `use Rack::Reducer::Middleware`.

## 1.0.1
### Added
- Improve inline documentation: https://www.rubydoc.info/gems/rack-reducer

## 1.0.0
First public release