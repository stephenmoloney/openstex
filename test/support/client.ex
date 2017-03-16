defmodule AppClient do
  @moduledoc :false
  use Openstex.Client, otp_app: :openstex, client: __MODULE__

  defmodule Swift do
    @moduledoc :false
    use Openstex.Swift.V1.Helpers, otp_app: :openstex, client: AppClient
  end
end