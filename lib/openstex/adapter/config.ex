defmodule Openstex.Adapter.Config do
  @moduledoc ~s"""
  An adapter module to be implemented by clients that using the `Openstex` library for the storage of config info.
  """

  defmacro __using__(_) do
    quote [] do
      @doc "Starts an agent for the storage of credentials in memory"
      def start_agent(_client),
        do: raise("Openstex.Adapter.Config.start_agent/2 has not been implemented.")

      @doc "Starts an agent for the storage of credentials in memory"
      def start_agent(_client, _opts),
        do: raise("Openstex.Adapter.Config.start_agent/2 has not been implemented.")

      @doc "Gets all the config.exs environment variables"
      def get_config_from_env(client, otp_app) do
        Application.get_env(otp_app, client, Application.get_all_env(otp_app))
      end

      @doc "Gets the keystone config.exs environment variables"
      def get_keystone_config_from_env(client, otp_app) do
        client
        |> get_config_from_env(otp_app)
        |> Keyword.fetch!(:keystone)
      end

      @doc "Gets the swift config.exs environment variables"
      def get_swift_config_from_env(client, otp_app) do
        client
        |> get_config_from_env(otp_app)
        |> Keyword.fetch!(:swift)
      end

      @doc "Gets the hackney config.exs environment variables"
      def get_hackney_config_from_env(client, otp_app) do
        client
        |> get_config_from_env(otp_app)
        |> Keyword.fetch!(:hackney)
      end

      @doc "Gets the openstack related config variables from a supervised Agent"
      def config(client) do
        Agent.get(agent_name(client), fn config -> config end)
      end

      @doc "Gets the keystone related config variables from a supervised Agent"
      def keystone_config(client) do
        Agent.get(agent_name(client), fn config -> config[:keystone] end)
      end

      @doc "Gets the swift related config variables from a supervised Agent"
      def swift_config(client) do
        Agent.get(agent_name(client), fn config -> config[:swift] end)
      end

      @doc "Gets the hackney_config related config variables from a supervised Agent"
      def hackney_config(client) do
        Agent.get(agent_name(client), fn config -> config[:hackney] end)
      end

      @doc "Gets the tenant_id config variable from a supervised Agent"
      def tenant_id(client) do
        Agent.get(agent_name(client), fn config -> config[:keystone][:tenant_id] end)
      end

      @doc "Gets the user_id config variable from a supervised Agent"
      def user_id(client) do
        Agent.get(agent_name(client), fn config -> config[:keystone][:user_id] end)
      end

      @doc "Gets the keystone_endpoint config variable from a supervised Agent"
      def keystone_endpoint(client) do
        Agent.get(agent_name(client), fn config -> config[:keystone][:endpoint] end)
      end

      @doc "Gets the swift_region config variable from a supervised Agent"
      def swift_region(client) do
        Agent.get(agent_name(client), fn config -> config[:swift][:region] end)
      end

      @doc "Gets the account_temp_url_key1 config variablesfrom a supervised Agent"
      def get_account_temp_url_key1(client) do
        Agent.get(agent_name(client), fn config -> config[:swift][:account_temp_url_key1] end)
      end

      @doc "Gets the account_temp_url_key2 config variable from a supervised Agent"
      def get_account_temp_url_key2(client) do
        Agent.get(agent_name(client), fn config -> config[:swift][:account_temp_url_key2] end)
      end

      @doc "Gets the account_temp_url_key1 config variables from a supervised Agent"
      def set_account_temp_url_key1(client, key) do
        Agent.update(agent_name(client), fn config -> put_account_key1(config, key) end)
      end

      @doc "Sets the account_temp_url_key2 config variable from a supervised Agent"
      def set_account_temp_url_key2(client, key) do
        Agent.update(agent_name(client), fn config -> put_account_key2(config, key) end)
      end

      defp agent_name(client) do
        Module.concat(__MODULE__, client)
      end

      defp put_account_key1(config, key) do
        swift_config = config[:swift]
        new_swift_config = Keyword.put(swift_config, :account_temp_url_key1, key)
        Keyword.put(config, :swift, new_swift_config)
      end

      defp put_account_key2(config, key) do
        swift_config = config[:swift]
        new_swift_config = Keyword.put(swift_config, :account_temp_url_key2, key)
        Keyword.put(config, :swift, new_swift_config)
      end

      @doc false
      def swift_service_name do
        "swift"
      end

      @doc false
      def swift_service_type do
        "object-store"
      end

      defoverridable start_agent: 1, start_agent: 2, swift_service_name: 0, swift_service_type: 0
    end
  end

  @callback start_agent(atom) :: {:ok, pid} | {:error, :already_started}
  @callback start_agent(atom, Keyword.t()) :: {:ok, pid} | {:error, :already_started}
  @callback config(atom) :: Keyword.t() | no_return
  @callback keystone_config(atom) :: Keyword.t()
  @callback swift_config(atom) :: Keyword.t()
  @callback hackney_config(atom) :: Keyword.t()
  @callback tenant_id(atom) :: Keyword.t()
  @callback user_id(atom) :: Keyword.t()
  @callback keystone_endpoint(atom) :: Keyword.t()
  @callback swift_region(atom) :: Keyword.t()
  @callback swift_service_name() :: String.t()
  @callback swift_service_type() :: String.t()
  @callback get_account_temp_url_key1(atom) :: Keyword.t()
  @callback get_account_temp_url_key2(atom) :: Keyword.t()
  @callback set_account_temp_url_key1(atom, String.t()) :: Keyword.t()
  @callback set_account_temp_url_key2(atom, String.t()) :: Keyword.t()
end
