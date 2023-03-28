defmodule PmLogin.Repo.Migrations.AddFieldToolGroup do
  use Ecto.Migration

  def change do
    alter table("tool_groups") do
      add :company_id, references("companies")
    end
  end
end
