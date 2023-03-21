defmodule PmLogin.Services.Type do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications_type" do
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(type, attrs) do
    type
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
