defmodule PmLogin.Repo.Migrations.ModifyUuidToString do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      modify :uuid, :string
    end
  end
end
