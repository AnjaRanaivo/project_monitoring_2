defmodule PmLogin.Services.ClientsRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Services.Tool
  alias PmLogin.Monitoring
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
    belongs_to :request_type, RequestType
    has_many :tasks, Task
    belongs_to :project, Project
    field :is_urgent, :boolean, default: false
    belongs_to :tool, Tool
    field :deadline, :date
    field :expectation, :string
    timestamps()
  end

  @doc false
  # def changeset(clients_request, attrs) do
  #   clients_request
  #   |> cast(attrs, [:title ,:content, :date_post, :seen, :date_seen, :ongoing, :date_ongoing, :done, :date_done, :finished, :date_finished, :active_client_id, :task_id, :project_id, :type_id, :uuid, :survey])
  #   # |> unique_constraint(:title, message: "Titre de requête déjà existant")
  #   |> unique_constraint(:uuid, message: "Identifiant du requête déja existant.")
  #   # |> validate_required(:content, message: "Entrez le contenu de votre requête")
  # end

  def changeset(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:title ,:content, :date_post, :seen, :date_seen, :ongoing, :date_ongoing, :done, :date_done, :finished, :date_finished, :active_client_id, :project_id, :request_type_id, :uuid, :survey, :is_urgent, :tool_id, :deadline, :expectation])
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

  def create_changeset_2(clients_request, attrs) do
    clients_request
    |> cast(attrs, [:title ,:content, :date_post, :seen, :ongoing, :done, :finished, :active_client_id, :uuid,
     :survey,:request_type_id, :tool_id, :is_urgent, :deadline, :expectation])
    |> foreign_key_constraint(:active_client_id)
    |> validate_required(:title, message: "Entrez l'intitulé de votre requête.")
    |> unique_constraint(:title, message: "Titre de requête déjà existant.")
    |> unique_constraint(:uuid, message: "Identifiant du requête déja existant.")
    |> validate_required(:content, message: "Entrez le contenu de votre requête.")
    |> validate_required(:expectation, message: "Entrez vos attentes.")
    |> validate_required(:deadline, message: "Entrez une date d'échéance.")
    |> Monitoring.validate_deadline_requests
    |> Monitoring.validate_tool_id_requests
    |> Monitoring.validate_type_id_requests
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
