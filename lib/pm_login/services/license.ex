defmodule PmLogin.Services.License do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.Company
  schema "licenses" do
    field :date_end, :date
    field :date_start, :date
    field :title, :string
    # field :company_id, :id
    belongs_to :company, Company

    timestamps()
  end

  @doc false
  def changeset(license, attrs) do
    license
    |> cast(attrs, [:title, :date_start, :date_end, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required(:company_id, message: "Entrez société")
    |> validate_required(:title, message: "Entrez titre")
    |> validate_required(:date_start, message: "Entrez date de début")
    |> validate_required(:date_end, message: "Entrez date de fin")
  end
end
