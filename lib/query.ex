defmodule Openstex.Query do
  @moduledoc false
    defstruct [:method, :uri, :params, :service, headers: []]
  @type t :: %__MODULE__{
                        method: atom,
                        uri: String.t,
                        headers: [{binary, binary}],
                        params: any,
                        service: atom
                        }
end


defmodule Openstex.Swift.Query do
  @moduledoc false
  defstruct [:method, :uri, :params, headers: [], service: :swift]
  @type t :: %__MODULE__{
                        method: atom,
                        uri: String.t,
                        headers: [{binary, binary}],
                        params: any,
                        service: :swift
                        }
end

defmodule Openstex.HttpQuery do
  @moduledoc false
  defstruct [method: :nil, uri: :nil, body: "", headers: [], options: [], service: :nil]
  @type t :: %__MODULE__{
                        method: atom,
                        uri: String.t,
                        body: :binary | {:file, :binary},
                        headers: [{binary, binary}],
                        options: Keyword.t,
                        service: atom
                        }
end