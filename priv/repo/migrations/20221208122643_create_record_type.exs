defmodule PmLogin.Repo.Migrations.CreateRecordType do
  use Ecto.Migration

  def change do
    create table(:record_types) do
      add :name, :string

      timestamps()
    end
  end
end
