# Openstex  [![Build Status](https://travis-ci.org/stephenmoloney/openstex_test.svg)](https://travis-ci.org/stephenmoloney/openstex_test) [![Hex Version](http://img.shields.io/hexpm/v/openstex.svg?style=flat)](https://hex.pm/packages/openstex) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/openstex)

An elixir client for making requests to [Openstack compliant apis](http://developer.openstack.org/api-ref.html).

#### Supported services

| Openstack Service | Supported |
|---|---|
| Identity 2.0 (Keystone) | :heavy_check_mark: |
| Object Storage 1.0 (Swift) | :heavy_check_mark: |


## Features

1. Query modules for generating query structs which can subsequently be sent to the API using a `request` function.
Example: *Creating a container:* [create_container/3](https://github.com/stephenmoloney/openstex/blob/master/lib/services/swift/v1/query.ex#L88).

2. Helper modules for

    a. One liners for sending queries to the client API. Example: *Getting the swift public url:* [get_public_url/0](https://github.com/stephenmoloney/openstex/blob/master/lib/services/swift/v1/helpers.ex#L21)

    b. Sending more complex queries such as multi-step queries to the client API. Example: *Getting all objects in a pseudofolder:* [list_objects/3](https://github.com/stephenmoloney/openstex/blob/master/lib/services/swift/v1/helpers.ex#L247)

3. The `Request.request/3` and `Transformation.request/3` protocols and associated implementations that send the queries and process the response.
Theoretically, the protocol can be extended so that queries are processed in a different manner is so required later during development
for particular request types.

4. Adapter modules for [OVH Webstorage CDN](https://www.ovh.com/fr/cdn/webstorage/), [OVH Cloudstorage](https://www.ovh.ie/cloud/storage/),
[Hubic](https://hubic.com/en/), [Rackspace Cloudfiles](https://www.rackspace.com/cloud/files)
and [Rackspace Cloudfiles CDN](https://www.rackspace.com/cloud/cdn-content-delivery-network).
All of the above Adapters provide access to Swift Object Storage services which are (mostly) openstack compliant.


## Installation and Getting Started

| Adapter | Getting started |
|---|---|
| [Ovh Cloudstorage Adapter](https://github.com/stephenmoloney/openstex/blob/master/lib/adapters/ovh/cloudstorage/adapter.ex) | [docs/ovh/cloudstorage/getting_started.md](https://github.com/stephenmoloney/openstex/blob/master/docs/ovh/cloudstorage/getting_started.md) |


# Usage

- Examples to be added. (for now see [openstex tests](https://github.com/stephenmoloney/openstex_test/tree/master/test))

## Tests

- To avoid circular dependency issues, tests are run from a separate repository [openstex_tests](https://github.com/stephenmoloney/openstex_test).

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
`

## Licence

[MIT Licence](LICENCE.md)
