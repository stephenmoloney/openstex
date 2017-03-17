# Openstex  [![Build Status](https://travis-ci.org/stephenmoloney/openstex_test.svg)](https://travis-ci.org/stephenmoloney/openstex_test) [![Hex Version](http://img.shields.io/hexpm/v/openstex.svg?style=flat)](https://hex.pm/packages/openstex) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/openstex)

An elixir client for making requests to [Openstack compliant apis](http://developer.openstack.org/api-ref.html).

### Supported services

| Openstack Service | Supported |
|---|---|
| Identity 2.0 (Keystone) | :heavy_check_mark: |
| Object Storage 1.0 (Swift) | :heavy_check_mark: |


### Features


### 1. Request modules for generating `HTTPipe.Conn.t` structs which can subsequently be sent
to the API using a `request` function.

- Example - creating a new container

```elixir
  account = Client.Swift.get_account()
  conn = Openstex.Swift.V1.create_container("new_container", account)
  client.request(conn)
```


### 2. Helper modules for

a. One liners for sending queries to the client API.

- Example - Uploading a file

```elixir
  file_path = Path.join(Path.expand(__DIR__, "priv/test.json")
  Client.Swift.upload_file(file_path, server_object, container,
```

b. Sending more complex queries such as multi-step queries to the client API.

- Example - Getting all objects in a pseudofolder recursively, `[nested: :true]` will
check for objects recursively in deeper folders.

```elixir
  file_path = Path.join(Path.expand(__DIR__, "priv/test.json")
  Client.Swift.list_objects("nested_folder", "new_container", [nested: :true])
```


### 3. Adapter modules for

- [OVH Cloudstorage](https://www.ovh.ie/cloud/storage/)
- [Rackspace Cloudfiles CDN](https://www.rackspace.com/cloud/cdn-content-delivery-network).
- [Rackspace Cloudfiles](https://www.rackspace.com/cloud/files)
- [Hubic](https://hubic.com/en/)


All of the above Adapters provide access to Swift Object Storage services which are (mostly) openstack compliant.



## Installation and Getting Started

| Adapter | Getting started |
|---|---|
| Ovh Adapter | [openstex_adapters_ovh](https://github.com/stephenmoloney/openstex/blob/master/lib/adapters/ovh/cloudstorage/adapter.ex) |


## Tests

- `mix test`


## Available Services

| Tables        | Version           | Status  |
| ------------- |:-------------:| -----:|
| Identity (Keystone) , [overview](https://wiki.openstack.org/wiki/keystone), [api](http://developer.openstack.org/api-ref-identity-v2.html)     | v2   | :heavy_check_mark:  |
| Identity (Keystone) , [overview](https://wiki.openstack.org/wiki/keystone), [api](http://developer.openstack.org/api-ref-identity-v3.html)     | v3   | :x: |
| Object Storage (Swift) , [overview](https://wiki.openstack.org/wiki/swift), [api](http://developer.openstack.org/api-ref-objectstorage-v1.html)     | v1   | :heavy_check_mark: |

[Openstack api reference](http://developer.openstack.org/api-ref.html)


## TODO

- [ ] improve the docs for some of the functions
- [ ] add tests for genserver workings in `Openstex.Adapters.Bypass.Keystone`
- [ ] add tests for `Openstex.Keystone.V2.HelpersTest`
- [ ] add tests for `Openstex.Swift.V1` with the execution of the `HTTPipe.Conn` structs with bypass.
`

## Licence

[MIT Licence](LICENCE.md)
