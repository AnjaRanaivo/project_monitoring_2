defmodule PmLogin.Repo.Migrations.ModifyUuidToUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:clients_requests, [:uuid])
  end
end
