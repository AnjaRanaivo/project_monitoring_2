defmodule PmLogin.Services.RequestType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "request_type" do
    field :name, :string
    timestamps()
  end

  @doc false
  def changeset(request_type, attrs) do
    request_type
    |> cast(attrs, [:name])

  end

end
