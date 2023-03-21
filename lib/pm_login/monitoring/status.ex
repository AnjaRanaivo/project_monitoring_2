defmodule PmLogin.Monitoring.Status do
  use Ecto.Schema
  import Ecto.Changeset

  schema "statuses" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
