defmodule PmLogin.Services.Tool do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tools" do
    field :name, :string
    field :tool_group_id, :id

    timestamps()
  end

  @doc false
  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
