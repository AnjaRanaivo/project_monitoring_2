defmodule PmLogin.Uuid do
  alias Ecto.UUID
  import Ecto.Query, warn: false

  alias PmLogin.Services

  ##################
  # Generate UUIDs #
  ##################
  def generate do
    uuid = UUID.generate() |> String.split("-")

    "REQ#{Enum.join([Enum.at(uuid, 0), Enum.at(uuid, 1)])}"
  end

end
