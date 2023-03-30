defmodule PmLogin.Repo.Migrations.AddClientRequestsIdTask do
  use Ecto.Migration

  def change do
    alter table("tasks") do
      add :clients_request_id, references("clients_requests")
    end
  end
end
