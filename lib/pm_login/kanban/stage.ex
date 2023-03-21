defmodule PmLogin.Kanban.Stage do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Kanban.{Position, Board, Card}

  schema "stages" do
    field :name, :string
    field :position, :integer
    field :status_id, :id
    timestamps()
    belongs_to :board, Board
    has_many :cards, Card
  end

  @doc false
  def create_changeset(stage, attrs) do
    stage
    |> cast(attrs, [:name, :board_id])
    |> validate_required([:name, :board_id])
    |> Position.insert_at_bottom(:board_id)
  end

  def create_from_project_changeset(stage, attrs) do
    stage
    |> cast(attrs, [:name, :board_id, :status_id])
    |> validate_required([:name, :board_id])
    |> Position.insert_at_bottom(:board_id)
  end

  def update_changeset(stage, attrs) do
    stage
    |> cast(attrs, [:name, :board_id, :position])
    |> validate_required([:name, :board_id, :position])
    |> Position.recompute_positions(:board_id)
  end
end
