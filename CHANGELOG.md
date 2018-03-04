# Changelog

## v0.4.1

[changes]
- updated deps
- added travis.yml
- swapped encoder from Poison -> Jason
- introduced standard elixir 1.6 formatting
- introduced credo linting

## v0.3.6

[enchancements]
- Add new function `delete_container/1`.

[changes]
-


## v0.3.5

[changes]
- More additions to the documentation for `delete_pseudofolder`,
- Remove the documentation from inside the `__using__` macros and
enhance the documentation in the `@callbacks` for Swift Helpers.

[bug fix]
- Fix function `pseudofolder_exists?/2` - previously was only checking for objects
at level below - needed to check for pseudofolders from one level higher up.


## v0.3.4

[changes]
- Add `generate_temp_url(String.t, String.t, list) ` to the documentation - which was
missing before from callbacks.


## v0.3.3

[changes]
- Add `list_containers` to the documentation - which was
missing before from callbacks.


## v0.3.2

[non-breaking changes]
- remove `test.exs`
- update `mapail` dependency to `1.0` - `Mapail` api changed.


## v0.3.1

[non-breaking changes]
- Flatten the filestructure in `/lib/openstex/adapter`

[enhancements]
- Add `list_containers!` and `list_containers` functions to `Swift.Helpers` module.
- Check for container existence in `list_objects` functions and return error if appropriate.


## v0.3.0

[neutral changes]
- Fix various compiler warnings
- Add tests using bypass (openstex_test repository will be deprecated)
- Remove dependency on the excellent `lau/calendar` as elixir core now contains required functions.
- Upgrade dependencies

[breaking changes]
- Remove the `defprotocol` abstraction and simplify. While protocols were a nice idea, it is
overengineered for the time being.
- Separate the adapters out of the repository into their own repos, namely:
  - `openstex_adapters_rackspace`
  - `openstex_adapters_ovh`

## v0.2.0

- Add functions `delete_object/3`, `delete_object!/3`
- Remove some duplicated docs from the `Openstex.Services.Swift.V1.Helpers` and have them on `@callback` only. (unfinished)