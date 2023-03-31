defmodule PmLogin.Repo.Migrations.CreateTasksHistory do
  use Ecto.Migration

  def change do
    create table(:tasks_history) do
      add :task_id, references(:tasks)
      add :intervener_id, references(:users)
      add :tracing_date, :naive_datetime
      add :status_from_id, references(:statuses)
      add :status_to_id, references(:statuses)
      add :reason, :string

      timestamps()
    end
  end
end
