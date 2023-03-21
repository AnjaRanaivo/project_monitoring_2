defmodule PmLogin.Repo.Migrations.CreateServicesType do
  use Ecto.Migration

  def change do
    create table(:notifications_type) do
      add :type, :string

      timestamps()
    end
  end
end
