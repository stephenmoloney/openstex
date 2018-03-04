defmodule Openstex.ResponseError do
  @moduledoc false
  defexception [:conn]

  def exception(conn: %HTTPipe.Conn{} = conn) do
    %__MODULE__{conn: conn}
  end

  def message(%__MODULE__{conn: conn}) do
    ~s"""
    The following http connection execution was unsuccessful, unexpected or erroneous in some way:

    Request Details:
    """ <> request_output(conn) <> "\nResponse Details:\n" <> response_output(conn)
  end

  def request_output(conn) do
    ~s"""
    ** Request Method **
        #{Kernel.inspect(conn.request.method)}

    ** Request Body **
        #{Kernel.inspect(conn.request.body)}

    ** Request Headers **
        #{Kernel.inspect(conn.request.headers)}

    ** Request Url **
        #{Kernel.inspect(conn.request.url)}
    """
  end

  def response_output(conn) do
    ~s"""
    ** Reponse Status Code **
        #{Kernel.inspect(conn.response.status_code)}

    ** Response Body **
        #{Kernel.inspect(conn.response.body)}

    ** Response Headers **
        #{Kernel.inspect(conn.response.headers)}
    """
  end
end
