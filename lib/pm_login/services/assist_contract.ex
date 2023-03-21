defmodule PmLogin.Services.AssistContract do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.Company

  schema "assist_contracts" do
    field :date_end, :date
    field :date_start, :date
    field :title, :string
    # field :company_id, :id
    belongs_to :company, Company
    timestamps()
  end

  @doc false
  def changeset(assist_contract, attrs) do
    assist_contract
    |> cast(attrs, [:title, :date_start, :date_end, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required([:title, :date_start, :date_end])
  end

  def create_changeset(assist_contract, attrs) do
    assist_contract
    |> cast(attrs, [:title, :date_start, :date_end, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required(:company_id, message: "Entrez société")
    |> validate_required(:title, message: "Entrez titre du contrat")
    |> validate_required(:date_start, message: "Entrez date de début du contrat")
    |> validate_required(:date_end, message: "Entrez date de fin du contrat")
  end
end
