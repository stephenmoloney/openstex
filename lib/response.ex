defmodule Openstex.Response do
  @moduledoc false
  defstruct [:body, :headers, :status_code]
  @type t :: %__MODULE__{
                                            body: map | binary | String.t,
                                            headers: list,
                                            status_code: integer
                                          }
end

defmodule Openstex.ResponseError do
  @moduledoc :false
  defexception [:response, :query]

  def message(%{query: query, response: resp}) do
    ~s"""
    The following http query was unsuccessful, unexpected or erroneous in some way:

    #{Kernel.inspect(query)} was unsuccessful.
    """
    <>
    message(%{response: resp})
  end

  def message(%{response: resp}) do
    ~s"""
    ** Reponse Status Code **
        #{inspect resp.status_code}

    ** Response Body **
        #{Kernel.inspect(resp.body)}

    ** Response Headers **
        #{Kernel.inspect(resp.headers)}
    """
  end
end