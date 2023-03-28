defmodule PmLogin.Services.ToolGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.Company

  schema "tool_groups" do
    field :name, :string
    belongs_to :company, Company

    timestamps()
  end

  @doc false
  def changeset(tool_group, attrs) do
    tool_group
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
