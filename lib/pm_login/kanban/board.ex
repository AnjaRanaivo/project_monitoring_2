defmodule PmLogin.Kanban.Board do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Monitoring.Project
  alias PmLogin.Kanban.Stage

  schema "boards" do
    field :name, :string
    timestamps()
    has_one :project, Project
    has_many(:stages, Stage)
    has_many(:cards, through: [:stages, :cards])
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
