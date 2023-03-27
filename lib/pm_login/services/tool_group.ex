defmodule PmLogin.Services.ToolGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tool_groups" do
    field :name, :string
    field :active_client_id, :id

    timestamps()
  end

  @doc false
  def changeset(tool_group, attrs) do
    tool_group
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
