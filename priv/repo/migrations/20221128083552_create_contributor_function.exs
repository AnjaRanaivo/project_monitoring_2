defmodule PmLogin.Repo.Migrations.CreateContributorFunction do
  use Ecto.Migration

  def change do
    create table(:contributor_functions) do
      add :title, :string
      timestamps()
    end
  end
end
