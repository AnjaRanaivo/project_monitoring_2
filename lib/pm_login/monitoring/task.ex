defmodule PmLogin.Monitoring.Task do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Monitoring
  alias PmLogin.Kanban.Card
  alias PmLogin.Login.User
  alias PmLogin.Services
  alias PmLogin.Monitoring.{Status,Priority,Comment,Project}

  schema "tasks" do
    field :date_end, :date
    field :date_start, :date
    field :deadline, :date
    field :estimated_duration, :integer
    field :performed_duration, :integer
    field :progression, :integer
    field :title, :string
    field :description; :text
    field :achieved_at, :naive_datetime
    field :hidden, :boolean
    field :without_control, :boolean
    field :is_major, :boolean
    # field :parent_id, :id
    # field :parent_id, :id
    # field :project_id, :id
    # field :contributor_id, :id
    # field :status_id, :id
    # field :priority_id, :id
    # field :attributor_id, :id
    has_many :children, PmLogin.Monitoring.Task, foreign_key: :parent_id, references: :id
    belongs_to :parent, PmLogin.Monitoring.Task
    has_one :card, Card
    belongs_to :contributor, User
    belongs_to :priority, Priority
    belongs_to :attributor, User
    belongs_to :status, Status
    has_many :comments, Comment
    belongs_to :project, Project
    # has_many :children, Task
    timestamps()
  end

  def hidden_changeset(task, attrs) do
    task
    |> cast(attrs, [:hidden])
  end

  #REAL CREATION
  def real_creation_changeset(task, attrs) do
    task
        |> cast(attrs, [:title, :description, :without_control,:attributor_id, :contributor_id, :project_id, :date_start, :estimated_duration, :deadline, :is_major])
        # |> validate_required(:title, message: "Entrez tâche")
        # |> unique_constraint(:title, message: "Tâche déjà existante")
        # |> validate_required(:estimated_duration, message: "Entrez estimation")
        # |> validate_required(:deadline, message: "Entrez date d'échéance")
        # |> Monitoring.validate_dates_without_dtend
        # |> Monitoring.validate_start_deadline
        # |> Monitoring.validate_positive_estimated
        |> put_change(:progression, 0)
        |> put_change(:performed_duration, 0)
        |> put_change(:priority_id, 2)
        |> put_change(:status_id, 1)
        # |> put_change(:date_start, Services.current_date |> NaiveDateTime.to_date)
        |> put_change(:inserted_at, Services.current_date)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :attributor_id, :progression, :date_start, :date_end, :estimated_duration, :performed_duration, :deadline, :is_major])
    |> validate_required([:title, :progression, :date_start, :date_end, :estimated_duration, :performed_duration, :deadline])
  end

  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :progression, :deadline,:date_start, :date_end, :estimated_duration, :performed_duration, :contributor_id, :priority_id, :status_id, :is_major])
    # |> Monitoring.validate_dates_without_deadline
    |> validate_required(:title, message: "Nom de tâche ne doit pas être vide!")
    |> validate_length(:title, max: 300, message: "Nom de tâche trop long !")
    |> validate_length(:description, max: 800, message: "Description trop longue !")
    |> Monitoring.validate_start_end
    |> Monitoring.validate_positive_estimated
    |> Monitoring.validate_start_deadline
    |> Monitoring.validate_positive_performed
    |> Monitoring.validate_progression
    |> Monitoring.del_contrib_id_if_nil
    |> put_change(:updated_at, Services.current_date)
  end

  def update_status_changeset(task, attrs) do
    task
    |> cast(attrs, [:status_id])
    |> record_achievement(attrs, task)
    |> put_change(:updated_at, Services.current_date)
  end

  def update_progression_changeset(task, attrs) do
    task
    |> cast(attrs, [:progression])
    |> Monitoring.validate_progression
    |> Monitoring.del_contrib_id_if_nil
    |> put_change(:updated_at, Services.current_date)
  end

  def secondary_changeset(task, attrs) do
    IO.inspect attrs
    task
    |> cast(attrs, [:parent_id, :without_control, :title, :description, :priority_id, :contributor_id,:attributor_id, :project_id,:date_start, :date_end, :estimated_duration, :deadline, :is_major])
    |> validate_required(:parent_id ,message: "Entrez une tâche parente")
    |> validate_required(:attributor_id,message: "La tâche n'a pas d'Attributeur")
    |> validate_required(:title, message: "Entrez tâche")
    |> unique_constraint(:title, message: "Tâche déjà existante")
    |> validate_length(:title, max: 300, message: "Nom de tâche trop long !")
    |> validate_length(:description, max: 800, message: "Description trop longue !")
    |> validate_required(:estimated_duration, message: "Entrez estimation")
    # |> validate_required(:date_start, message: "Entrez date de début")
    # |> validate_required(:date_end, message: "Entrez date de fin")
    |> validate_required(:deadline, message: "Entrez date d'échéance")
    |> Monitoring.validate_start_end
    |> Monitoring.validate_dates_without_dtend
    |> Monitoring.validate_start_deadline
    |> Monitoring.validate_positive_estimated
    |> put_change(:progression, 0)
    |> put_change(:performed_duration, 0)
    |> put_change(:status_id, 1)
    |> put_change(:date_start, Services.current_date |> NaiveDateTime.to_date)
    |> put_change(:inserted_at, Services.current_date)
  end

  def create_changeset(task, attrs) do
    # %{"project_id" => pro_id, "title" => title} = attrs
    #
    #   project = Monitoring.get_project!(pro_id)
    #   board = Kanban.get_board!(project.board_id)
    #   stage = Kanban.get_stage_by_position!(board.id,0)
    #
    # case Kanban.create_card(%{name: title, stage_id: stage.id}) do
    #   {:ok, card} ->
      # IO.puts("tafiditra create task")
      # IO.inspect(attrs)
        task
        |> cast(attrs, [:title, :description, :without_control,:attributor_id, :contributor_id, :project_id, :date_start, :estimated_duration, :deadline, :is_major])
        |> validate_required(:title, message: "Entrez tâche")
        |> unique_constraint(:title, message: "Tâche déjà existante")
        |> validate_length(:title, max: 300, message: "Nom de tâche trop long !")
        |> validate_length(:description, max: 800, message: "Description trop longue !")
        |> validate_required(:estimated_duration, message: "Entrez estimation")
        # |> validate_required(:date_start, message: "Entrez date de début")
        |> validate_required(:deadline, message: "Entrez date d'échéance")
        |> Monitoring.validate_dates_without_dtend
        |> Monitoring.validate_start_deadline
        |> Monitoring.validate_positive_estimated
        |> put_change(:progression, 0)
        # |> put_change(:status_id, stage.status_id)
        # |> put_change(:project_id, pro_id)
        |> put_change(:performed_duration, 0)
        |> put_change(:priority_id, 2)
        |> put_change(:status_id, 1)
        |> put_change(:date_start, Services.current_date |> NaiveDateTime.to_date)
        |> put_change(:inserted_at, Services.current_date)


        # {:error, %Ecto.Changeset{} = changeset} ->
        # task
        # |> cast(attrs, [:title, :date_start, :date_end, :estimated_duration, :deadline])
        # |> validate_required(:title, message: "Entrez tâche")
        # |> unique_constraint(:title, message: "Tâche déjà existante")
        # |> validate_required(:estimated_duration, message: "Entrez estimation")
        # |> validate_required(:date_start, message: "Entrez date de début")
        # |> validate_required(:date_end, message: "Entrez date de fin")
        # |> validate_required(:deadline, message: "Entrez date d'échéance")
        # |> Monitoring.validate_dates
        # |> Monitoring.validate_start_end
        # |> Monitoring.validate_start_deadline
        # |> Monitoring.validate_positive_estimated
        # |> put_change(:progression, 0)
        # # |> put_change(:card_id, card.id)
        # |> put_change(:status_id, stage.status_id)
        # |> put_change(:project_id, project.id)
        # |> put_change(:performed_duration, 0)
        # |> put_change(:priority_id, 2)
        # |> put_change(:status_id, 1)

  end

  def update_moth_prg_changeset(task, attrs) do
    task
    |> cast(attrs, [:progression])
    |> Monitoring.validate_progression_mother
  end

  def record_achievement(changeset, attrs, task) do
    # IO.puts "/////"
    # IO.inspect task.status_id
    # IO.inspect attrs
    # changeset |> get_field(:status_id) |> IO.inspect
    new_status = changeset |> get_field(:status_id) |> IO.inspect
    cond do
      task.status_id != 5 and new_status == 5 ->
        IO.puts "achevée"
        changeset |> put_change(:achieved_at, NaiveDateTime.local_now)
      true -> changeset
    end

  end

end
