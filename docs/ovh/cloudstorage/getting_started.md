## Getting started - OVH Cloudstorage


### Installation

- Add `:ex_ovh` and `:openstex` to your project list of dependencies.

```elixir
defp deps() do
  [
    {:ex_ovh, "~> 0.2"},
    {:openstex, github: "stephenmoloney/openstex"}
  ]
end
```

### Add

### Configure ExOvh Client

- Configure an ExOvh Client

    - Create an OVH account at [OVH](https://www.ovh.com/)

    - Create an API application at the [OVH API page](https://eu.api.ovh.com/createApp/). Follow the
      steps outlined by OVH there.

    - Alternatively, there is a [mix task](https://github.com/stephenmoloney/ex_ovh/blob/master/docs/mix_task.md) which can help
      generate the OVH application.

    - The mix task (if used) will generate a config file as follows:

```elixir
config :my_app, MyApp.Cloudstorage,
  ovh: [
    application_key: System.get_env("MY_APP_CLOUDSTORAGE_APPLICATION_KEY"),
    application_secret: System.get_env("MY_APP_CLOUDSTORAGE_APPLICATION_SECRET"),
    consumer_key: System.get_env("MY_APP_CLOUDSTORAGE_CONSUMER_KEY")
  ]
```

- Add additional configuration as needed or as known.


### Add client modules to your elixir application

```elixir
defmodule MyApp.Cloudstorage do
  @moduledoc :false
  use Openstex.Client, otp_app: :my_app, client: __MODULE__

  defmodule SwiftHelpers do
    @moduledoc :false
    use Openstex.Services.Swift.V1.Helpers, otp_app: :my_app, client: MyApp.Cloudstorage
  end

  defmodule Ovh do
    @moduledoc :false
    use ExOvh.Client, otp_app: :my_app, client: __MODULE__
  end
end
```


### Configure Cloudstorage client (ovh openstack client)

```elixir
config :my_app, MyApp.Cloudstorage,
  adapter: Openstex.Adapters.Ovh.Cloudstorage.Adapter,
  ovh: [
    application_key: System.get_env("MY_APP_CLOUDSTORAGE_APPLICATION_KEY"),
    application_secret: System.get_env("MY_APP_CLOUDSTORAGE_APPLICATION_SECRET"),
    consumer_key: System.get_env("MY_APP_CLOUDSTORAGE_CONSUMER_KEY"),
    endpoint: "ovh-eu", # optional
    api_version: "1.0" # optional
  ],
  keystone: [
    tenant_id: System.get_env("MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TENANT_ID"), # mandatory, corresponds to an ovh project id or ovh servicename
    user_id: System.get_env("MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_USER_ID"), # optional, if absent a user will be created using the ovh api.
    endpoint: "https://auth.cloud.ovh.net/v2.0"
  ],
  swift: [
    account_temp_url_key1: System.get_env("MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TEMP_URL_KEY1"), # defaults to :nil if absent
    account_temp_url_key2: System.get_env("MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TEMP_URL_KEY2"), # defaults to :nil if absent
    region: :nil # defaults to "SBG1" if not set.
  ]
```

- ***Note:*** The `MY_APP_CLOUDSTORAGE` maps to the module name `MyApp.Cloudstorage`.
`MY_APP_CLOUDSTORAGE` <==> `MyApp.Cloudstorage`


Optionally add the `httpoison` settings to the above:
```
httpoison: [
  connect_timeout: 20000,
  receive_timeout: 180000
]
```

- Ensure that the following variables are available as environment variables.

```shell
export MY_APP_CLOUDSTORAGE_APPLICATION_KEY=<KEY>
export MY_APP_CLOUDSTORAGE_APPLICATION_SECRET=<SECRET>
export MY_APP_CLOUDSTORAGE_CONSUMER_KEY=<KEY>

export MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TENANT_ID=<TENANT_ID>
export MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_USER_ID=<USER_ID>
export MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TEMP_URL_KEY1=<KEY1>
export MY_APP_CLOUDSTORAGE_CLOUDSTORAGE_TEMP_URL_KEY2=<KEY2>
```

- Add the environment variables to the enviroment. Eg run ```source .env```

- To configure the first `application key`, `application_secret` and `consumer_key` environment variables,
it's easier to use the [mix task](https://github.com/stephenmoloney/ex_ovh/blob/master/docs/mix_task.md).
The following variables will then be added to `.env` by the mix task.
```
export MY_APP_CLOUDSTORAGE_APPLICATION_KEY=<KEY>
export MY_APP_CLOUDSTORAGE_APPLICATION_SECRET=<SECRET>
export MY_APP_CLOUDSTORAGE_CONSUMER_KEY=<KEY>
```

- To get the `tenant_id`, user [ex_ovh](https://hex.pm/packages/ex_ovh):
```
ExOvh.Services.V1.Cloud.Query.list_services() |> MyApp.Cloudstorage.Ovh.request!()
```


### Add the cloudstorage client (`Openstex.Cloudstorage`) to your project supervision tree.


```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false
  spec1 = [supervisor(MyApp.Endpoint, [])]
  spec2 = [supervisor(MyApp.Cloudstorage, [])]
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(spec1 ++ spec2, opts)
end
```


### Examples

    client = MyApp.Cloudstorage

- An example of an API call to a swift API using the Helper functions (higher level):

 ```elixir
file_on_client = "/priv/test_file.json"
server_file = "test/nested/test_file.json"
container = "default"
client.swift().upload_file(file_on_client, server_file, container, [recv_timeout: (60000 * 60)])
 ```

- An example of an API call to a swift API using the Query functions (lower level):


 ```elixir
new_container = "my_new_container"
account = client.swift().get_account()
container_metadata = [headers: [{"X-Container-Meta-Access-Control-Allow-Origin", "http://stephenmoloney.com"}]]
create_container(new_container, account, container_metadata) |> client.request()
 ```

- An example of manually constructed query call to a swift API using the Query functions (low level):

```elixir
%Openstex.Swift.Query{
                      method: :get,
                      uri: account,
                      params: %{query_string: %{"format" => "json"}}
                    }
|> client.request()
```

- An example of manually constructed query call to a swift API using the Query functions (lowest level):


```elixir
%Openstex.HttpQuery{
                   method: :get,
                   uri: account,
                   body: "",
                   headers: [{"Content-Type", "application/json; charset=utf-8"}],
                   options: [timeout: 10000, recv_timeout: 30000],
                   service: :openstack
                   }
|> client.prepare_request()
|> client.request()
```
