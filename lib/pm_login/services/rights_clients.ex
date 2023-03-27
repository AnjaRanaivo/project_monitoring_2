defmodule PmLogin.Services.Rights_clients do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rights_clients" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(rights_clients, attrs) do
    rights_clients
    |> cast(attrs, [:name])
    |> validate_required(:name, message: "Ne peut pas être vide")
  end
end
