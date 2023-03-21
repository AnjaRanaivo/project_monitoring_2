defmodule PmLogin.Repo.Migrations.AddCurrentRecordToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :current_record_id, :id
    end
  end
end
