defmodule PmLogin.Repo.Migrations.CreateTaskRecords do
  use Ecto.Migration

  def change do
    create table(:task_records) do
      add :date, :date
      add :task_id, references("tasks")
      add :user_id, references("users")
      add :start, :naive_datetime
      add :end, :naive_datetime
      add :duration, :integer
      timestamps()
    end
  end
end
