defmodule PmLogin.Monitoring.TaskHistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Login.User
  alias PmLogin.Monitoring.Task
  alias PmLogin.Monitoring.Status
  alias PmLogin.Services

  schema "tasks_history" do
    belongs_to :task, Task
    belongs_to :intervener, User
    field :tracing_date, :naive_datetime
    belongs_to :status_from, Status
    belongs_to :status_to, Status
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(task_history, attrs) do
    task_history
    |> cast(attrs, [:task_id, :intervener_id, :tracing_date, :status_from_id, :status_to_id, :reason])
    |> validate_required([:task_id, :intervener_id, :status_from_id, :status_to_id])
  end

  def create_changeset(record, attrs) do
    record
    |> cast(attrs, [:task_id, :intervener_id, :tracing_date, :status_from_id, :status_to_id, :reason])
    |> put_tracing_date()
    |> put_reason()
    |> put_change(:inserted_at, Services.current_date)
  end

  defp put_tracing_date(changeset) do
    changeset
    |> put_change(:tracing_date, Services.current_date)
  end

  defp put_reason(changeset) do
    changeset
    |> validate_length(:reason, max: 1000, message: "Motif trop long !")
  end

  def update_reason_changeset(task_history, attrs) do
    task_history
    |> cast(attrs, [:reason])
    |> put_reason()
    |> put_change(:updated_at, Services.current_date)
  end

end
