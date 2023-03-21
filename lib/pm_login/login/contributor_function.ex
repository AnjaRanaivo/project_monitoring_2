defmodule PmLogin.Login.ContributorFunction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contributor_functions" do
    field :title, :string

    timestamps()
  end

  def changeset(function, attrs) do
    function
    |> cast(attrs, [:title])
  end

  def create_changeset(function, attrs) do
    function
    |> cast(attrs, [:title])
  end

end
