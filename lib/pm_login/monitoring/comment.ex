defmodule PmLogin.Monitoring.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Login.User
  alias PmLogin.Services

  schema "comments" do
    field :content, :string
    field :task_id, :id
    field :file_urls, {:array, :string}, default: []

    # field :poster_id, :id

    belongs_to :poster, User
    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end

  def create_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :poster_id, :task_id])
    |> validate_required(:content, message: "Vous ne pouvez pas entrer un commentaire vide.")
    |> put_change(:inserted_at, NaiveDateTime.local_now)
  end

  def upload_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:file_urls])
  end
end
