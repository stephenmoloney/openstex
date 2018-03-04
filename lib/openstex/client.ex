defmodule Openstex.Client do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias HTTPipe.{Conn, Request}
      alias Openstex.{Request, ResponseError, Transformation}
      @behaviour Openstex.Client

      # public callback functions

      @doc false
      def client do
        Keyword.fetch!(unquote(opts), :client)
      end

      @doc false
      def __adapter__ do
        client = Keyword.fetch!(unquote(opts), :client)
        otp_app = Keyword.fetch!(unquote(opts), :otp_app)

        otp_app
        |> Application.get_env(client, Application.get_all_env(otp_app))
        |> Keyword.fetch!(:adapter)
      end

      @doc false
      def config do
        __adapter__().config()
      end

      @doc false
      def keystone do
        __adapter__().keystone()
      end

      @doc false
      def swift do
        Module.concat(client(), Swift)
      end

      @doc "Starts the openstex supervision tree."
      def start_link(sup_opts \\ []) do
        client = Keyword.fetch!(unquote(opts), :client)
        otp_app = Keyword.fetch!(unquote(opts), :otp_app)

        Openstex.Supervisor.start_link(client, otp_app: otp_app)
      end

      @doc "Prepares a request prior to sending by adding metadata such as authorization headers."
      @spec prepare_request(Conn.t() | Request.t()) :: Conn.t()
      def prepare_request(%HTTPipe.Request{} = request) do
        Conn.new()
        |> Map.put(:request, request)
        |> prepare_request()
      end

      def prepare_request(%HTTPipe.Conn{} = conn) do
        client = Keyword.fetch!(unquote(opts), :client)

        Request.apply_transformations(conn, client)
      end

      @doc "Sends a request to the openstack api using the [httpipe](https://hex.pm/packages/httpipe) and
      the [hackney_adapter](https://hex.pm/packages/httpipe_adapters_hackney)."
      @spec request(Conn.t() | Request.t()) :: {:ok, Conn.t()} | {:error, Conn.t()}
      def request(conn) do
        client = Keyword.fetch!(unquote(opts), :client)

        Request.request(conn, client)
      end

      @doc "Sends a request to the openstack api using the [httpipe](https://hex.pm/packages/httpipe) and
      the [hackney_adapter](https://hex.pm/packages/httpipe_adapters_hackney)."
      @spec request!(Conn.t() | Request.t()) :: Conn.t() | no_return
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
  @callback prepare_request(Conn.t() | Request.t()) :: Conn.t()
  @callback request(Conn.t() | Request.t()) :: {:ok, Conn.t()} | {:error, Conn.t()}
  @callback request!(Conn.t() | Request.t()) :: Conn.t() | no_return
end
