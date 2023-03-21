defmodule PmLogin.Kanban.Card do
  use Ecto.Schema
  import Ecto.Changeset

  alias PmLogin.Kanban.{Stage, Position}
  alias PmLogin.Monitoring.Task

  schema "cards" do
    field :name, :string
    timestamps()
    belongs_to(:stage, Stage)
    belongs_to :task, Task
    field(:position, :integer)
    # field :task_id, :id
  end

  @doc false
  def create_changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :stage_id, :task_id])
    |> validate_required([:name, :stage_id, :task_id])
    |> Position.insert_at_bottom(:stage_id)
  end

  def update_changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :stage_id, :position])
    |> validate_required([:name, :stage_id, :position])
    |> Position.recompute_positions(:stage_id)
  end

  def update_mother_changeset(card, attrs) do
    card
    |> cast(attrs, [:stage_id])
    |> Position.insert_at_bottom(:stage_id)
  end

  def update_stage_changeset(card, attrs) do
    card
    |> cast(attrs, [:stage_id])
    |> Position.insert_at_bottom(:stage_id)
  end


end
