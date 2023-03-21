defmodule PmLogin.Repo.Migrations.CreateRequestType do
  use Ecto.Migration

  def change do
    create table(:request_type) do
      add :name, :string
      timestamps()
    end
  end
end
