defmodule Openstex do
  @moduledoc ~S"""
  Examples setting up clients for use with openstex.

  ## OVH Cloudstorage Client

      defmodule Openstex.Cloudstorage do
        @moduledoc :false
        use Openstex.Client, otp_app: :openstex, client: __MODULE__

        defmodule Swift do
          @moduledoc :false
          use Openstex.Swift.V1.Helpers, otp_app: :openstex, client: Openstex.Cloudstorage
        end

        defmodule Ovh do
          @moduledoc :false
          use ExOvh.Client, otp_app: :openstex, client: __MODULE__
        end
      end


  ## Rackspace Cloudfiles Client

      defmodule Openstex.Cloudfiles do
        @moduledoc :false
        use Openstex.Client, otp_app: :openstex, client: __MODULE__

        defmodule Swift do
          @moduledoc :false
          use Openstex.Swift.V1.Helpers, otp_app: :openstex, client: Openstex.Cloudfiles
        end
      end


  ## Rackspace CloudfilesCDN Client

      defmodule Openstex.Cloudfiles.CDN do
        @moduledoc :false
        use Openstex.Client, otp_app: :openstex, client: __MODULE__

        defmodule Swift do
          @moduledoc :false
          use Openstex.Swift.V1.Helpers, otp_app: :openstex, client: Openstex.Cloudfiles.CDN
        end
      end


  ## Hubic Client

      defmodule Openstex.ExHubic do
        @moduledoc :false
        use Openstex.Client, otp_app: :openstex, client: __MODULE__

        defmodule Swift do
          @moduledoc :false
          use Openstex.Swift.V1.Helpers, otp_app: :openstex, client: Openstex.ExHubic
        end

        defmodule Hubic do
          @moduledoc :false
          use ExHubic.Client, otp_app: :openstex, client: __MODULE__
        end
      end
  """
end



