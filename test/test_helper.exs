defmodule Openstex.TestCase do
  use ExUnit.CaseTemplate, async: false
end

Application.ensure_all_started(:hackney)
Application.ensure_all_started(:bypass)
AppClient.start_link()
ExUnit.start()
