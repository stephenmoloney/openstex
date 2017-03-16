# Changelog


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