defmodule PmLogin.Uuid do
  alias Ecto.UUID
  import Ecto.Query, warn: false

  alias PmLogin.Services

  ##################
  # Generate UUIDs #
  ##################
  def generate do
    current_year = DateTime.utc_now.year
    last_id = length(Services.list_requests_by_year(current_year))
    # uuid = UUID.generate() |> String.split("-")

    # "REQ#{Enum.join([Enum.at(uuid, 0), Enum.at(uuid, 1)])}"
    "PM#{last_id}#{current_year}"
  end

end
