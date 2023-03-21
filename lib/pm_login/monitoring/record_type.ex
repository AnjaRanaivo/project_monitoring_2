defmodule PmLogin.Monitoring.RecordType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "record_types" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(type, attrs) do
    type
    |> cast(attrs, [:name])
  end

end
