# Changelog

## v0.3.2

[non-breaking changes]
- Add `.travis.yml` for github tests.
- remove `test.exs`


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