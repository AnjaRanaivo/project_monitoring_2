defmodule PmLogin.Services.Editor do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.Company

  schema "editors" do
    field :title, :string
    # field :company_id, :id
    belongs_to :company, Company

    timestamps()
  end

  @doc false
  def changeset(editor, attrs) do
    editor
    |> cast(attrs, [:title, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required(:title, message: "Entrez titre")
    |> validate_required(:company_id, message: "Entrez société")
  end

  def update_changeset(editor, attrs) do
    editor
    |> cast(attrs, [:title, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required(:title, message: "Entrez titre")
    |> validate_required(:company_id, message: "Entrez société")
  end

  def create_changeset(editor, attrs) do
    editor
    |> cast(attrs, [:title, :company_id])
    |> unique_constraint(:title, message: "Titre déjà pris")
    |> validate_required(:title, message: "Entrez titre")
    |> validate_required(:company_id, message: "Entrez société")
  end
end
