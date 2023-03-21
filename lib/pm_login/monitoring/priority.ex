defmodule PmLogin.Monitoring.Priority do
  use Ecto.Schema
  import Ecto.Changeset

  schema "priorities" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(priority, attrs) do
    priority
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
