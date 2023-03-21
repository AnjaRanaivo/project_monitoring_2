defmodule PmLogin.Repo.Migrations.BooleanToFalseByDefault do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      modify :seen, :boolean, default: false
      modify :ongoing, :boolean, default: false
      modify :done, :boolean, default: false
      modify :finished, :boolean, default: false
    end
  end
end
