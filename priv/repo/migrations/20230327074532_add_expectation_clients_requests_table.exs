defmodule PmLogin.Repo.Migrations.AddExpectationClientsRequestsTable do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :expectation, :string
    end
  end
end
