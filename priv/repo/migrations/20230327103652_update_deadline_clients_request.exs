defmodule PmLogin.Repo.Migrations.UpdateDeadlineClientsRequest do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      modify :deadline, :date
    end
  end
end
