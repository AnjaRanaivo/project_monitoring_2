defmodule PmLogin.Repo.Migrations.RemoveTaskIdClientRequests do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      remove :task_id, :id
    end
  end
end
