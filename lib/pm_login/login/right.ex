defmodule PmLogin.Login.Right do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rights" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(right, attrs) do
    right
    |> cast(attrs, [:title])
    |> validate_required(:title, message: "Entrez un titre")
    |> unique_constraint(:title, message: "Titre de statut déjà existant")
  end
end
