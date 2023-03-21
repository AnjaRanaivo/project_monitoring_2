defmodule PmLogin.Repo.Migrations.AddFieldDateToClientsRequests do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :date_seen, :naive_datetime
      add :date_ongoing, :naive_datetime
      add :date_done, :naive_datetime
      add :date_finished, :naive_datetime
    end
  end
end
