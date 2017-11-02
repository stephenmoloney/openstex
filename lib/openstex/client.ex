defmodule Openstex.Client do


  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Openstex.{Request, ResponseError, Transformation}
      @behaviour Openstex.Client

      # public callback functions

      @doc :false
      def client(), do: Keyword.fetch!(unquote(opts), :client)

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
      def swift(), do: Module.concat(client(), Swift)

      @doc "Starts the openstex supervision tree."
      def start_link(sup_opts \\ []) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        otp_app = unquote(opts) |> Keyword.fetch!(:otp_app)
        Openstex.Supervisor.start_link(client, [otp_app: otp_app])
      end

      @doc "Prepares a request prior to sending by adding metadata such as authorization headers."
      @spec prepare_request(HTTPipe.Conn.t | HTTPipe.Request.t) :: HTTPipe.Conn.t
      def prepare_request(%HTTPipe.Request{} = request) do
        Map.put(HTTPipe.Conn.new(), :request, request)
        |> prepare_request()
      end
      def prepare_request(%HTTPipe.Conn{} = conn) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        Request.apply_transformations(conn, client)
      end

      @doc "Sends a request to the openstack api using the [httpipe](https://hex.pm/packages/httpipe) and
      the [hackney_adapter](https://hex.pm/packages/httpipe_adapters_hackney)."
      @spec request(HTTPipe.Conn.t| HTTPipe.Request.t) :: {:ok, HTTPipe.Conn.t} | {:error, HTTPipe.Conn.t}
      def request(conn) do
        client = unquote(opts) |> Keyword.fetch!(:client)
        Request.request(conn, client)
      end

      @doc "Sends a request to the openstack api using the [httpipe](https://hex.pm/packages/httpipe) and
      the [hackney_adapter](https://hex.pm/packages/httpipe_adapters_hackney)."
      @spec request!(HTTPipe.Conn.t| HTTPipe.Request.t) :: HTTPipe.Conn.t | no_return
      def request!(conn) do
        case request(conn) do
          {:ok, conn} -> conn
          {:error, conn} -> raise(ResponseError, conn: conn)
        end
      end


    end
  end


  @callback start_link() :: {:ok, pid} | {:error, atom}
  @callback start_link(sup_opts :: list) :: {:ok, pid} | {:error, atom}
  @callback prepare_request(HTTPipe.Conn.t | HTTPipe.Request.t) :: HTTPipe.Conn.t
  @callback request(HTTPipe.Conn.t | HTTPipe.Request.t) :: {:ok, HTTPipe.Conn.t} | {:error, HTTPipe.Conn.t}
  @callback request!(HTTPipe.Conn.t | HTTPipe.Request.t) :: HTTPipe.Conn.t | no_return

end