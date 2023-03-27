defmodule PmLogin.Repo.Migrations.CreateToolGroups do
  use Ecto.Migration

  def change do
    create table(:tool_groups) do
      add :name, :string
      add :active_client_id, references(:active_clients, on_delete: :nothing)

      timestamps()
    end

    create index(:tool_groups, [:active_client_id])
  end
end
