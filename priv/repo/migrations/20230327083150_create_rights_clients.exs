defmodule PmLogin.Repo.Migrations.CreateRightsClients do
  use Ecto.Migration

  def change do
    create table(:rights_clients) do
      add :name, :string

      timestamps()
    end
  end
end
