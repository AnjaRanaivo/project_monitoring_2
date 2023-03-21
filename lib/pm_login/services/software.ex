defmodule PmLogin.Services.Software do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.Company

  schema "softwares" do
    field :title, :string
    # field :company_id, :id
    belongs_to :company, Company


    timestamps()
  end

  @doc false
  def changeset(software, attrs) do
    software
    |> cast(attrs, [:title, :company_id])
    |> unique_constraint(:title, message: "Nom de logiciel déjà pris")
    |> validate_required(:title, message: "Entrez nom de logiciel")
    |> validate_required(:company_id, message: "Entrez société")
  end
end
