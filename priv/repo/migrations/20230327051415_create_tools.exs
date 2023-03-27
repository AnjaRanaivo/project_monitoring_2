defmodule PmLogin.Repo.Migrations.CreateTools do
  use Ecto.Migration

  def change do
    create table(:tools) do
      add :name, :string
      add :tool_group_id, references(:tool_groups, on_delete: :nothing)

      timestamps()
    end

    create index(:tools, [:tool_group_id])
  end
end
