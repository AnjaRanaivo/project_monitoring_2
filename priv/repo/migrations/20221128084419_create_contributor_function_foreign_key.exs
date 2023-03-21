defmodule PmLogin.Repo.Migrations.CreateContributorFunctionForeignKey do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :function_id, references("contributor_functions")
    end
  end
end
