defmodule PmLogin.Repo.Migrations.CreateSurveyFieldForClientRequest do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :survey, :map, default: %{}
    end
  end
end
