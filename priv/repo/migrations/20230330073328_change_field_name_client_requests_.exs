defmodule PmLogin.Repo.Migrations.ChangeFieldNameClientRequests do
  use Ecto.Migration

  def change do
    rename table(:clients_requests), :type_id, to: :request_type_id
  end
end
