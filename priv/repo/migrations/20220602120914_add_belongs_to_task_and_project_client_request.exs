defmodule PmLogin.Repo.Migrations.AddBelongsToTaskAndProjectClientRequest do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :task_id, references("tasks")
      add :project_id, references("projects")
    end
  end
end
