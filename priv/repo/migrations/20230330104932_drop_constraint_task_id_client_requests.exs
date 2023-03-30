defmodule PmLogin.Repo.Migrations.DropConstraintTaskIdClientRequests do
  use Ecto.Migration

  def change do
    drop constraint(:clients_requests ,"clients_requests_task_id_fkey")
  end
end
