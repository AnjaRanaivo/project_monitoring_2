defmodule PmLogin.Monitoring.TaskRecord do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Monitoring.Task

  schema "task_records" do
    field :date, :date
    # field :task_id, :id
    belongs_to :task, Task
    field :user_id, :id
    field :start, :naive_datetime
    field :end, :naive_datetime
    field :duration, :integer

    timestamps()
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:date, :task_id, :user_id, :start, :end, :duration])
  end

  def create_changeset(record, attrs) do
    record
    |> cast(attrs, [:date, :task_id, :user_id, :start])
    |> put_default_dates()
  end

  defp put_default_dates(changeset) do
    changeset
    |> put_change(:date, NaiveDateTime.local_now() |> NaiveDateTime.to_date())
    |> put_change(:start, NaiveDateTime.local_now())
  end

  def end_changeset(record, attrs) do
    record
    |> cast(attrs, [:end, :duration])
  end

end
