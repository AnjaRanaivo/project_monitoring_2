defmodule PmLogin.Monitoring.Planified do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Login.User

  schema "planified" do
    field :description, :string
    field :dt_start, :naive_datetime
    field :period, :integer
    # field :attributor_id, :integer
    # field :contributor_id, :integer
    field :project_id, :integer
    field :estimated_duration, :integer
    field :without_control, :boolean, default: false

    belongs_to :attributor, User
    belongs_to :contributor, User

    timestamps()
  end

  @doc false
  def create_changeset(planified, attrs) do
    planified
    |> cast(attrs, [:description, :dt_start, :period, :project_id, :attributor_id, :contributor_id, :estimated_duration, :without_control])
    |> validate_required(:description, message: "Entrez description de tâche")
    |> validate_required(:dt_start, message: "Entrez la date de début de la tâche planifiée")
    |> validate_required(:period, message: "Entrez période de planification")
    |> validate_required(:estimated_duration, message: "Entrez la durée estimée")
    |> validate_period
    |> validate_estimated_duration
  end

  def changeset(planified, attrs) do
    planified
    |> cast(attrs, [:description, :dt_start, :period, :project_id, :attributor_id, :contributor_id, :estimated_duration, :without_control])
  end

  #CREATION SAMPLES
  #day = NaiveDateTime.new(~D[2010-10-02], ~T[12:00:00.000])
  # Monitoring.create_planified(%{description: "Tâche planifiée 3",
  #                               dt_start: the_day, period: 2, project_id: 24, attributor_id: 57,
  #                               estimated_duration: 2, without_control: false})

  def validate_period(changeset) do
    period = get_field(changeset, :period)
    cond do
      period <= 0 -> add_error(changeset, :period, "Période invalide")
      true -> changeset
    end
  end

  def validate_estimated_duration(changeset) do
    estimated_duration = get_field(changeset, :estimated_duration)
    cond do
      estimated_duration <= 0 -> add_error(changeset, :estimated_duration, "Durée estimée invalide")
      true -> changeset
    end
  end

end
