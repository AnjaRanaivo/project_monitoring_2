defmodule PmLogin.Monitoring.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Task
  alias PmLogin.Kanban
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Kanban.Board
  alias PmLogin.Services

  schema "projects" do
    field :date_end, :date
    field :date_start, :date
    field :deadline, :date
    field :description, :string
    field :estimated_duration, :integer
    field :performed_duration, :integer
    field :progression, :integer
    field :title, :string
    # field :active_client_id, :id
    field :status_id, :id
    # field :board_id, :id
    has_many :tasks, Task
    belongs_to :active_client, ActiveClient
    belongs_to :board, Board

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :description, :progression, :date_start, :date_end, :estimated_duration, :performed_duration, :deadline, :active_client_id, :status_id])
    |> validate_required([:title, :description, :progression, :date_start, :date_end, :estimated_duration, :performed_duration, :deadline, :active_client_id, :status_id])
  end

  def update_changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :description,:date_start, :date_end, :estimated_duration, :deadline, :active_client_id, :status_id])
    |> foreign_key_constraint(:active_client_id)
    |> unique_constraint(:title, message: "Ce nom de projet existe déjà")
    |> validate_required(:estimated_duration, message: "Entrez la durée estimée du projet")
    |> validate_required(:title, message: "Veuillez entrer le nom de votre projet")
    |> validate_required(:description, message: "Aucune description donnée")
    |> validate_required(:date_start, message: "Entrez une date de début")
    # |> validate_required(:date_end, message: "Entrez une date de fin")
    |> validate_required(:estimated_duration, message: "Entrez une estimation en heure")
    |> validate_required(:deadline, message: "Entrez la date d'échéance")
  end

  def create_changeset(project, attrs) do
    %{"title" => project_title} = attrs

    case Kanban.create_board(%{name: project_title}) do
      {:ok, board} ->
        for status <- Monitoring.list_statuses do
          Kanban.create_stage_from_project(%{name: status.title, board_id: board.id, status_id: status.id})
        end
        project
        |> cast(attrs, [:title, :description,:date_start, :date_end, :estimated_duration, :deadline, :active_client_id])
        |> foreign_key_constraint(:active_client_id)
        |> unique_constraint(:title, message: "Ce nom de projet existe déjà")
        |> validate_required(:estimated_duration, message: "Entrez la durée estimée du projet")
        |> validate_required(:title, message: "Veuillez entrer le nom de votre projet")
        |> validate_required(:description, message: "Aucune description donnée")
        # |> validate_required(:date_start, message: "Entrez une date de début")
        # |> validate_required(:date_end, message: "Entrez une date de fin")
        |> validate_required(:estimated_duration, message: "Entrez une estimation en heure")
        |> validate_required(:deadline, message: "Entrez la date d'échéance")
        |> Monitoring.validate_dates
        |> Monitoring.validate_start_end
        |> Monitoring.validate_start_deadline
        |> Monitoring.validate_positive_estimated
        |> put_default_progression
        |> put_change(:board_id, board.id)
        |> put_change(:performed_duration, 0)
        |> put_change(:status_id, 1)
        |> put_change(:date_start, Services.current_date |> NaiveDateTime.to_date)



      {:error, %Ecto.Changeset{} = _changeset} ->
        project
        |> cast(attrs, [:title, :description,:date_start, :date_end, :estimated_duration, :deadline, :active_client_id])
        |> foreign_key_constraint(:active_client_id)
        |> unique_constraint(:title, message: "Ce nom de projet existe déjà")
        |> validate_required(:estimated_duration, message: "Entrez la durée estimée du projet")
        |> validate_required(:title, message: "Veuillez entrer le nom de votre projet")
        |> validate_required(:description, message: "Aucune description donnée")
        # |> validate_required(:date_start, message: "Entrez une date de début")
        # |> validate_required(:date_end, message: "Entrez une date de fin")
        |> validate_required(:estimated_duration, message: "Entrez une estimation en heure")
        |> validate_required(:deadline, message: "Entrez la date d'échéance")
        |> Monitoring.validate_dates
        |> Monitoring.validate_start_end
        |> Monitoring.validate_start_deadline
        |> Monitoring.validate_positive_estimated
        |> put_default_progression
        |> put_change(:performed_duration, 0)
        |> put_change(:status_id, 1)
    end

  end

  defp put_default_progression(changeset) do
    changeset |> put_change(:progression, 0)
  end

  def update_progression_cs(project, attrs) do
    project
    |> cast(attrs, [:progression])
    |> Monitoring.validate_progression_mother
  end





end
