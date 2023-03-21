defmodule PmLogin.Repo.Migrations.CreateRequestTypeForeignKey do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :type_id, references("request_type")
    end
  end
end
