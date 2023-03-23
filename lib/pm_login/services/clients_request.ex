defmodule PmLogin.Services.ClientsRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Monitoring.Task
  alias PmLogin.Monitoring.Project
  alias PmLogin.Services.RequestType

  schema "clients_requests" do
    field :survey, :map, default: %{}
    field :uuid, :string
    field :title, :string
    field :content, :string
    field :date_post, :naive_datetime
    field :seen, :boolean, default: false
    field :date_seen, :naive_datetime
    field :ongoing, :boolean, default: false
    field :date_ongoing, :naive_datetime
    field :done, :boolean, default: false
    field :date_done, :naive_datetime
    field :finished, :boolean, default: false
    field :date_finished, :naive_datetime
    field :file_urls, {:array, :string}, default: []
    # field :active_client_id, :id
    belongs_to :active_client, ActiveClient
    belongs_to :type, RequestType
    belongs_to :task, Task
    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:title ,:content, :date_post, :seen, :date_seen, :ongoing, :date_ongoing, :done, :date_done, :finished, :date_finished, :active_client_id, :task_id, :project_id, :type_id, :uuid, :survey])
    # |> unique_constraint(:title, message: "Titre de requête déjà existant")
    |> unique_constraint(:uuid, message: "Identifiant du requête déja existant.")
    # |> validate_required(:content, message: "Entrez le contenu de votre requête")
  end

  def create_changeset(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:title ,:content, :date_post, :seen, :ongoing, :done, :finished, :active_client_id, :uuid, :survey])
    |> foreign_key_constraint(:active_client_id)
    |> validate_required(:title, message: "Entrez l'intitulé de votre requête.")
    |> unique_constraint(:title, message: "Titre de requête déjà existant.")
    |> unique_constraint(:uuid, message: "Identifiant du requête déja existant.")
    |> validate_required(:content, message: "Entrez le contenu de votre requête.")
    |> put_change(:date_post, NaiveDateTime.local_now)
    |> put_change(:seen, false)
    |> put_change(:ongoing, false)
    |> put_change(:done, false)
    |> put_change(:finished, false)
  end

  def create_changeset_with_project(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:title ,:content, :date_post, :seen, :ongoing, :done, :finished, :project_id, :active_client_id, :uuid, :survey])
    |> foreign_key_constraint(:active_client_id)
    |> validate_required(:title, message: "Entrez l'intitulé de votre requête.")
    |> unique_constraint(:title, message: "Titre de requête déjà existant.")
    |> unique_constraint(:uuid, message: "Identifiant du requête déja existant.")
    |> validate_required(:content, message: "Entrez le contenu de votre requête.")
    |> put_change(:date_post, NaiveDateTime.local_now)
    |> put_change(:seen, false)
    |> put_change(:ongoing, false)
    |> put_change(:done, false)
    |> put_change(:finished, false)
  end

  def upload_changeset(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:file_urls])
  end
end
