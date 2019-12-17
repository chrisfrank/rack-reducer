# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.3 - 2019-12-19

### Fixed
- #14: Support nested parameters in Rails (@danielpuglisi)

## 2.0.2 - 2019-10-05

### Fixed
- #11: Refresh dataset on every request in Rails apps (@chase439)
- #10: Fix syntax errors in a README example (@th-ad)

## 2.0.0 - 2019-05-02

### Removed
- Drop the deprecated 'mixin-style' API.
- Drop the deprecated middleware API. Middleware remains supported via
  `use Rack::Reducer::Middleware`.

### Changed
- Update `Rack::Reducer.new` to instantiate a reducer, instead of reserving it
  for the old Middleware API.
- Refer to `::new` intead of `::create` in the docs. Note that `::create`
  remains supported as an alias of `::new`.


## 1.1.2 - 2019-04-24

### Fixed
- Restore support for nested params hashes, missing since 1.1

## 1.1.1 - 2019-04-17

### Fixed
- #6: Restore support for default filters when params are empty (danielpuglisi).
- Run rails-specific specs in a separate process to avoid polluting other specs.

## 1.1.0 - 2019-03-30

### Fixed
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
