defmodule Openstex.Client do
  alias Openstex.{HttpQuery, Query, Response}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Openstex.{Response, ResponseError, Request, Transformation}
      @behaviour Openstex.Client

      # public callback functions

      @doc :false
      def __adapter__() do
        client = unquote(opts) |> Keyword.fetch!(:client)
        otp_app = unquote(opts) |> Keyword.fetch!(:otp_app)
        case Application.get_env(otp_app, client) do
          :nil -> Application.get_all_env(otp_app)
           config -> config
        end
        |> Keyword.fetch!(:adapter)
      end

      @doc :false
      def config(), do: __adapter__().config()

      @doc :false
      def keystone(), do: __adapter__().keystone()

      @doc :false
      def swift(), do: Module.concat(Keyword.fetch!(unquote(opts), :client), SwiftHelpers)


      @doc "Starts the openstex supervision tree."
      def start_link(sup_opts \\ []) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        otp_app = unquote(opts) |> Keyword.fetch!(:otp_app)
        Openstex.Supervisor.start_link(client, [otp_app: otp_app])
      end

      @doc "Prepares a request prior to sending by adding metadata such as authorization headers."
      @spec prepare_request(Query.t, Keyword.t) :: {:ok, Response.t} | {:error, Response.t}
      def prepare_request(query, httpoison_opts \\ []) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        Transformation.prepare_request(query, httpoison_opts, client)
      end

      @doc "Sends a request to the openstack api using [httpoison](https://hex.pm/packages/httpoison)."
      @spec request(Query.t | HttpQuery.t, Keyword.t) :: {:ok, Response.t} | {:error, Response.t}
      def request(query, httpoison_opts \\ []) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        Request.request(query, httpoison_opts, client)
      end

      @doc "Sends a request to the openstack api using [httpoison](https://hex.pm/packages/httpoison)."
      @spec request!(Query.t | HttpQuery.t, Keyword.t) :: Response.t | no_return
      def request!(query, httpoison_opts \\ []) do
        case request(query) do
          {:ok, resp} -> resp
          {:error, resp} -> raise(ResponseError, response: resp, query: query)
        end
      end


    end
  end


  @callback start_link() :: {:ok, pid} | {:error, atom}
  @callback start_link(sup_opts :: list) :: {:ok, pid} | {:error, atom}
  @callback prepare_request(query :: Query.t) :: Query.t | no_return
  @callback prepare_request(query :: Query.t, httpoison_opts :: Keyword.t) :: Query.t | no_return
  @callback request(query :: Query.t | HttpQuery.t) :: {:ok, Response.t} | {:error, Response.t}
  @callback request(query :: Query.t | HttpQuery.t, httpoison_opts :: Keyword.t) :: {:ok, Response.t} | {:error, Response.t}
  @callback request!(query :: Query.t | HttpQuery.t) :: {:ok, Response.t} | no_return
  @callback request!(query :: Query.t | HttpQuery.t, httpoison_opts :: Keyword.t) :: {:ok, Response.t} | no_return


end