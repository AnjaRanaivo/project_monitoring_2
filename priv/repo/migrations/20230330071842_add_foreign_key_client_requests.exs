defmodule PmLogin.Repo.Migrations.AddForeignKeyClientRequests do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      remove :type_id, :id
    end
  end
end
