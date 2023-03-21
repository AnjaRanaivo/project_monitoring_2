defmodule PmLogin.Repo.Migrations.AddRecordTypeToRecord do
  use Ecto.Migration

  def change do
    alter table("task_records") do
      add :record_type, references("record_types")
    end
  end
end
