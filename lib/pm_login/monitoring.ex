defmodule PmLogin.Monitoring do
  @moduledoc """
  The Monitoring context.
  """
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import PmLogin.Utilities
  alias PmLogin.Repo
  alias PmLogin.Kanban
  alias PmLogin.Monitoring.{Status, Task, Planified, Priority, TaskRecord, TaskHistory}
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Services.ToolGroup
  alias PmLogin.Services.Tool
  alias PmLogin.Services.Company
  alias PmLogin.Login.User
  alias PmLogin.Login
  alias PmLogin.Kanban.Stage
  alias PmLogin.Services
  alias PmLogin.Services.RequestType
  alias PmLogin.Login.User
  alias PmLogin.Kanban.{Board, Stage, Card}
  alias PmLogin.Services.{ClientsRequest, ActiveClient}

  @topic inspect(__MODULE__)
  def subscribe do
    Phoenix.PubSub.subscribe(PmLogin.PubSub, @topic)
  end

  defp broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(PmLogin.PubSub, @topic, {__MODULE__, event, result})
  end

  def hidden_subscribe do
    Phoenix.PubSub.subscribe(PmLogin.PubSub, "hidden_subscription")
  end

  defp broadcast_hidden_change(tuple, event) do
    Phoenix.PubSub.broadcast(
      PmLogin.PubSub,
      "hidden_subscription",
      {"hidden_subscription", event, tuple}
    )
  end

  # TASK RECORDS

  def end_record(%TaskRecord{} = record, attrs) do
    record
    |>TaskRecord.end_changeset(attrs)
    |>Repo.update
  end

  def get_record!(record_id) do
    query = from r in TaskRecord,
            where: r.id == ^record_id
    Repo.one(query)
  end

  def create_task_record(attrs \\ %{}) do
    %TaskRecord{}
    |> TaskRecord.create_changeset(attrs)
    |> Repo.insert()
  end

  def change_task_record(%TaskRecord{} = task_record, attrs \\ %{}) do
    TaskRecord.changeset(task_record, attrs)
  end

  def list_task_records_by_user(user_id) do
    query = from tr in TaskRecord,
            where: tr.user_id == ^user_id,
            preload: [:task]
    Repo.all(query)
  end

  def list_todays_task_records_by_user(user_id) do
    today = NaiveDateTime.local_now()
    list_task_records_by_user(user_id)
    |> Enum.filter(fn tr ->
      (today.year == tr.start.year) and (today.month == tr.start.month) and (today.day == tr.start.day)
    end)
  end

  def list_task_records do
    Repo.all(TaskRecord)
  end

  def filter_task_title(text, title) do
    Regex.match?(~r/^#{text}/i, title)
  end

  # DATE CALCULUS

  def avg_working_hours(%Task{} = t) do
    case working_days(t.date_start, t.deadline) do
      0 -> 0
      _ -> trunc(t.estimated_duration / working_days(t.date_start, t.deadline))
    end
  end

  def working_days(d1, d2) do
    Date.range(d1, Date.add(d2, -1))
    |> Enum.count(fn day -> is_working_day?(day) end)
  end

  def diff_between_dates do
    Date.diff(~D[2021-05-10], ~D[2021-05-04])
  end

  def is_working_day?(day) do
    Date.day_of_week(day) != 6 and Date.day_of_week(day) != 7
  end

  # checking user right in board

  def is_admin?(id) do
    user = Login.get_user!(id)
    user.right_id == 1
  end

  def is_attributor?(id) do
    user = Login.get_user!(id)
    user.right_id == 2
  end

  def is_contributor?(id) do
    user = Login.get_user!(id)
    user.right_id == 3
  end

  # Date validations and positive estimation with progression

  def del_contrib_id_if_nil(changeset) do
    contributor_id = get_field(changeset, :contributor_id)

    case contributor_id do
      nil -> changeset |> delete_change(:contributor_id)
      _ -> changeset
    end
  end

  def validate_progression(changeset) do
    progression = get_field(changeset, :progression)

    case progression do
      nil ->
        changeset

      _ ->
        cond do
          progression < 0 or progression > 100 ->
            add_error(
              changeset,
              :invalid_progression,
              "Progression doit être comprise entre 0 et 100"
            )

          not is_integer(progression) ->
            add_error(changeset, :progression_not_int, "Entrez un entier")

          true ->
            changeset
        end
    end
  end

  def validate_progression_mother(changeset) do
    progression = get_field(changeset, :progression)

    case progression do
      nil ->
        changeset

      _ ->
        cond do
          progression < 0 -> put_change(changeset, :progression, 0)
          progression > 100 -> put_change(changeset, :progression, 100)
          # not is_integer progression -> add_error(changeset, :progression_not_int, "Entrez un entier")
          true -> changeset
        end
    end
  end

  def validate_positive_performed(changeset) do
    est = get_field(changeset, :performed_duration)

    case est do
      nil ->
        changeset

      _ ->
        cond do
          est < 0 ->
            changeset |> add_error(:negative_performed, "La durée exécutée ne peut être négative")

          true ->
            changeset
        end
    end
  end

  def validate_positive_estimated(changeset) do
    est = get_field(changeset, :estimated_duration)

    case est do
      nil ->
        changeset

      _ ->
        cond do
          est < 0 ->
            changeset |> add_error(:negative_estimated, "La durée estimée ne peut être négative")

          true ->
            changeset
        end
    end
  end

  def validate_tool_id_requests(changeset) do
    tool_id = get_field(changeset, :tool_id)
    case tool_id do
      nil ->
        changeset

      _ ->
        cond do
          tool_id <= 0 ->
            changeset |> add_error(
              :tool_id,
              "Choisissez l'outil concerné")

          true ->
            changeset
        end
    end
  end

  def validate_type_id_requests(changeset) do
    type_id = get_field(changeset, :request_type_id)
    case type_id do
      nil ->
        changeset

      _ ->
        cond do
          type_id <= 0 ->
            changeset |> add_error(
              :request_type_id,
              "Choisissez le type de la requête")

          true ->
            changeset
        end
    end
  end

  def validate_start_deadline(changeset) do
    date_start = get_field(changeset, :date_start)
    deadline = get_field(changeset, :deadline)

    if date_start != nil and deadline != nil do
      dt_start = date_start |> to_string |> string_to_date
      dt_deadline = deadline |> to_string |> string_to_date

      case Date.compare(dt_deadline, dt_start) do
        :lt ->
          changeset
          |> add_error(
            :deadline_before_dtstart,
            "La date d'échéance ne peut pas être antérieure à la date de début"
          )

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_deadline_requests(changeset) do
    # date_start = get_field(changeset, :date_post)
    today = Date.utc_today()
    deadline = get_field(changeset, :deadline)

    if deadline != nil do
      dt_deadline = deadline |> to_string |> string_to_date
      cond do
        Date.compare(dt_deadline, today) == :lt ->
          changeset
          |> add_error(
            :deadline,
            "La date d'échéance ne peut pas être antérieure à aujourd'hui"
          )
          true ->
            changeset
        end
      else
        changeset
      end
  end

  def validate_start_end(changeset) do
    date_start = get_field(changeset, :date_start)
    date_end = get_field(changeset, :date_end)

    if date_start != nil and date_end != nil do
      dt_start = date_start |> to_string |> string_to_date
      dt_end = date_end |> to_string |> string_to_date

      case Date.compare(dt_end, dt_start) do
        :lt ->
          # IO.puts "startEnd"
          changeset
          |> add_error(
            :dt_end_lt_start,
            "La date finale ne peut pas être antérieure à la date de début"
          )

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_dates_without_deadline(changeset) do
    today = Date.utc_today()
    date_start = get_field(changeset, :date_start)
    date_end = get_field(changeset, :date_end)

    if date_start != nil and date_end != nil do
      dt_start = date_start |> to_string |> string_to_date
      dt_end = date_end |> to_string |> string_to_date

      cond do
        Date.compare(dt_start, today) == :lt ->
          changeset
          |> add_error(
            :date_start_lt,
            "La date de début ne peut pas être antérieure à aujourd'hui"
          )

        Date.compare(dt_end, today) == :lt ->
          changeset
          |> add_error(:date_end_lt, "La date de fin ne peut pas être antérieure à aujourd'hui")

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_dates_without_dtend(changeset) do
    today = Date.utc_today()
    date_start = get_field(changeset, :date_start)
    deadline = get_field(changeset, :deadline)

    # IO.puts(date_start != "" and date_end != "" and deadline != "")
    if date_start != nil and deadline != nil do
      dt_start = date_start |> to_string |> string_to_date
      dt_deadline = deadline |> to_string |> string_to_date

      cond do
        Date.compare(dt_start, today) == :lt ->
          changeset
          |> add_error(
            :date_start_lt,
            "La date de début ne peut pas être antérieure à aujourd'hui"
          )

        Date.compare(dt_deadline, today) == :lt ->
          changeset
          |> add_error(
            :deadline_lt,
            "La date d'échéance ne peut pas être antérieure à aujourd'hui"
          )

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_dates(changeset) do
    today = Date.utc_today()
    date_start = get_field(changeset, :date_start)
    date_end = get_field(changeset, :date_end)
    deadline = get_field(changeset, :deadline)

    # IO.puts(date_start != "" and date_end != "" and deadline != "")
    if date_start != nil and date_end != nil and deadline != nil do
      dt_start = date_start |> to_string |> string_to_date
      dt_end = date_end |> to_string |> string_to_date
      dt_deadline = deadline |> to_string |> string_to_date

      cond do
        Date.compare(dt_start, today) == :lt ->
          changeset
          |> add_error(
            :date_start_lt,
            "La date de début ne peut pas être antérieure à aujourd'hui"
          )

        Date.compare(dt_end, today) == :lt ->
          changeset
          |> add_error(:date_end_lt, "La date de fin ne peut pas être antérieure à aujourd'hui")

        Date.compare(dt_deadline, today) == :lt ->
          changeset
          |> add_error(
            :deadline_lt,
            "La date d'échéance ne peut pas être antérieure à aujourd'hui"
          )

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def string_to_date(str) do
    [str_y, str_m, str_d] = String.split(str, "-")
    [y, m, d] = [String.to_integer(str_y), String.to_integer(str_m), String.to_integer(str_d)]
    {:ok, date} = Date.new(y, m, d)
    date
  end

  @doc """
  Returns the list of statuses.

  ## Examples

      iex> list_statuses()
      [%Status{}, ...]

  """
  def list_statuses do
    query =
      from s in Status,
        order_by: [asc: :id]

    Repo.all(query)
  end

  # Get title and id of status
  def list_statuses_title do
    query = from s in Status,
            select: {s.title, s.id},
            order_by: [asc: :id]

    Repo.all(query)
  end

  def list_statuses_for_tasks_table do
    query =
      from s in Status,
        where: s.id != 5,
        order_by: [asc: :id]

    Repo.all(query)
  end

  @doc """
  Gets a single status.

  Raises `Ecto.NoResultsError` if the Status does not exist.

  ## Examples

      iex> get_status!(123)
      %Status{}

      iex> get_status!(456)
      ** (Ecto.NoResultsError)

  """
  def get_status!(id), do: Repo.get!(Status, id)

  @doc """
  Creates a status.

  ## Examples

      iex> create_status(%{field: value})
      {:ok, %Status{}}

      iex> create_status(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_status(attrs \\ %{}) do
    %Status{}
    |> Status.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a status.

  ## Examples

      iex> update_status(status, %{field: new_value})
      {:ok, %Status{}}

      iex> update_status(status, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_status(%Status{} = status, attrs) do
    status
    |> Status.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a status.

  ## Examples

      iex> delete_status(status)
      {:ok, %Status{}}

      iex> delete_status(status)
      {:error, %Ecto.Changeset{}}

  """
  def delete_status(%Status{} = status) do
    Repo.delete(status)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking status changes.

  ## Examples

      iex> change_status(status)
      %Ecto.Changeset{data: %Status{}}

  """
  def change_status(%Status{} = status, attrs \\ %{}) do
    Status.changeset(status, attrs)
  end

  # PLANIFIED

  def list_spawners do
    Supervisor.which_children(PmLogin.SpawnerSupervisor)
  end

  def list_spawners_states do
    for {_, pid, _, _} <- list_spawners() do
      :sys.get_state(pid)
    end
  end

  def list_spawners_pids do
    for {_, pid, _, _} <- list_spawners() do
      pid
    end
  end

  def get_planified_pid(planified_id) do
    pids = list_spawners_pids()

    Enum.find(pids, fn pid ->
      state_map = :sys.get_state(pid)
      planified_id == state_map[:planified].id
    end)
  end

  def terminate_spawner(planified_id) do
    pid = get_planified_pid(planified_id)
    DynamicSupervisor.terminate_child(PmLogin.SpawnerSupervisor, pid)
  end

  def change_planified(%Planified{} = planified, attrs \\ %{}) do
    Planified.changeset(planified, attrs)
  end

  def get_planified!(id) do
    query =
      from p in Planified,
        where: p.id == ^id

    Repo.one(query)
  end

  def delete_planified(%Planified{} = planified) do
    Repo.delete(planified)
  end

  def list_planified() do
    query =
      from p in Planified,
        order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_planified_by_project(project_id) do
    attributor_query = from(u in User)
    contributor_query = from(us in User)

    query =
      from p in Planified,
        preload: [attributor: ^attributor_query, contributor: ^contributor_query],
        order_by: [desc: :inserted_at],
        where: p.project_id == ^project_id

    Repo.all(query)
  end

  def create_planified(attrs \\ %{}) do
    %Planified{}
    |> Planified.create_changeset(attrs)
    |> Repo.insert()
  end

  def broadcast_planified({:ok, result}) do
    broadcast_change({:ok, result}, [:planified, :created])
  end

  def broadcast_planified_deletion({:ok, result}) do
    broadcast_change({:ok, result}, [:planified, :deleted])
  end

  alias PmLogin.Monitoring.Project

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    query =
      from p in Project,
        order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_project_by_title!(project_title) do
    project_search = "%#{project_title}%"

    query = from p in Project,
            where: ilike(p.title, ^project_search) or ilike(p.description, ^project_search),
            order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_project_by_id!(project_id) do

    query = from p in Project,
            where: p.id == ^project_id,
            order_by: [desc: :inserted_at]

    Repo.one(query)
  end

  def list_project_by_status!(status_id) do
    query = from p in Project,
            where: p.status_id == ^status_id,
            order_by: [desc: :inserted_at]

    Repo.all(query)
  end



  def list_projects_by_contributor(con_id) do
    tasks_query =
      from t in Task,
        where: t.contributor_id == ^con_id

    query =
      from p in Project,
        preload: [tasks: ^tasks_query],
        order_by: [desc: :inserted_at]

    Repo.all(query)
    |> Enum.filter(fn %PmLogin.Monitoring.Project{} = project ->
      project.tasks != []
    end)
  end

  # def list_tasks_by_contributor(con_id) do
  #  query = from t in Task, where: t.contributor_id == ^con_id
  #
  #  Repo.all(query)
  # end

  def list_tasks_by_contributor(contributor_id) do
    query = from t in Task,
            where: t.contributor_id == ^contributor_id,
            preload: [:project],
            order_by: [desc: t.inserted_at]
    Repo.all(query)
  end

  def list_tasks_by_contributor_project(con_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
        where: t.contributor_id == ^con_id,
        preload: [:project, :status, :priority, card: ^card_query],
        order_by: [desc: t.priority_id]

    Repo.all(query)
  end

  def list_tasks_by_contributor_or_attributor(con_id) do
    query =
      from t in Task,
        where: t.contributor_id == ^con_id or t.attributor_id == ^con_id,
        preload: [:project, :status, :priority]

    Repo.all(query)
  end

  def list_tasks_by_attributor_project(con_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
        # Récupérer les tâches en étant un contributeur
        where: t.contributor_id == ^con_id,
        preload: [:project, :status, :priority, card: ^card_query],
        order_by: [desc: t.priority_id]

    Repo.all(query)
  end

  def list_attributes_tasks_by_attributor_project(con_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
        # Récupérer les tâches en étant un contributeur
        where: t.attributor_id == ^con_id,
        preload: [:project, :status, :priority, card: ^card_query],
        order_by: [desc: t.priority_id]

    Repo.all(query)
  end

  def list_attributors_by_own_tasks(attributor_id) do
    task_query =
      from t in Task,
      where: t.contributor_id == ^attributor_id and t.status_id != 5,
      select: t.attributor_id

    result = Repo.all(task_query)

    query =
      from u in User,
      where: u.id in ^result,
      select: {u.username, u.id}

    Repo.all(query)
  end

  def list_contributors_by_attributed_tasks(attributor_id) do
    task_query =
      from t in Task,
      where: t.attributor_id == ^attributor_id and t.status_id != 5,
      select: t.contributor_id

    result = Repo.all(task_query)

    query =
      from u in User,
      where: u.id in ^result,
      select: {u.username, u.id}

    Repo.all(query)
  end

  def remove_card(task_id) do
    task_query =
      from t in Task,
        where: t.id == ^task_id,
        select: t

    query =
      from c in Card,
        where: c.task_id == ^task_id,
        select: c

    Repo.delete_all(query)
    Repo.delete_all(task_query)
  end

  # def remove_task(task_id) do
  #   query =
  #     from t in Task,
  #       where: t.id == ^task_id,
  #       select: t

  #   Repo.delete_all(query)
  # end

  # Récupérer les tâches qui sont pas encore terminées ou achevées
  def list_tasks_not_achieved(con_id) do
    tasks = list_tasks_by_attributor_project(con_id)
    tasks |> Enum.filter(fn task -> task.status_id != 5 end)
  end

  def list_tasks_attributed_not_achieved(con_id) do
    tasks = list_attributes_tasks_by_attributor_project(con_id)
    tasks |> Enum.filter(fn task -> task.status_id != 5 end)
  end

  def list_tasks_not_achieved_for_contributor(con_id) do
    tasks = list_tasks_by_contributor_project(con_id)
    tasks |> Enum.filter(fn task -> task.status_id != 5 end)
  end

  def add_progression_to_project(%Project{} = p) do
    primary_len = count_primaries(p)
    up_rate = 1 / primary_len * 100
    prog = p.progression + trunc(up_rate)
    update_project_progression(p, %{"progression" => prog})

    # round progression to 0 or 100
    project = get_project!(p.id)
    update_project_progression(project, %{"progression" => round_project_progression(p.id)})
  end

  def substract_progression_to_project(%Project{} = p) do
    primary_len = count_primaries(p)
    up_rate = 1 / primary_len * 100
    prog = p.progression - trunc(up_rate)
    update_project_progression(p, %{"progression" => prog})

    # round progression to 0 or 100
    project = get_project!(p.id)
    update_project_progression(project, %{"progression" => round_project_progression(p.id)})
  end

  def substract_project_progression_when_creating_primary(%Project{} = p) do
    primary_len = count_primaries(p) + 1
    IO.puts(primary_len)

    up_rate =
      case primary_len do
        0 -> 0
        _ -> 1 / primary_len * 100
      end

    prog = p.progression - (p.progression - trunc(up_rate))
    update_project_progression(p, %{"progression" => prog})

    # round progression to 0 or 100
    project = get_project!(p.id)
    update_project_progression(project, %{"progression" => round_project_progression(p.id)})
  end

  def get_task_mother!(id) do
    card_ch_query = from(c in Card)

    children_query =
      from ch in Task,
        preload: [card: ^card_ch_query]

    query =
      from t in Task,
        where: t.id == ^id,
        preload: [children: ^children_query]

    Repo.one!(query)
  end

  def is_task_mother?(%Task{} = t) do
    task = get_task_mother!(t.id)
    length(task.children) > 0
  end

  def achieve_children_tasks(%Task{} = t, curr_user_id) do
    task = get_task_mother!(t.id)

    for child <- task.children do
      stage_id = get_achieved_stage_id_from_project_id!(child.project_id)
      Kanban.put_childcard_to_achieve(child.card, %{"stage_id" => stage_id})
      update_task(child, %{"status_id" => 5})
    end

    update_task(task, %{"progression" => 100})

    Services.send_notifs_to_admins_and_attributors(
      curr_user_id,
      "Tâche #{task.title} a été achevée avec toutes ses tâches filles.",
      4
    )
  end

  def put_task_to_achieve(%Task{} = t, curr_user_id) do
    stage_id = get_achieved_stage_id_from_project_id!(t.project_id)

    task = get_task_with_card!(t.id)

    project = get_project_with_tasks!(t.project_id)

    Kanban.put_card_to_achieve(task.card, %{"stage_id" => stage_id})
    update_task(task, %{"status_id" => 5})

    if is_a_child?(task) do
      update_mother_task_progression(task, curr_user_id)
    end

    if is_task_primary?(task) do
      add_progression_to_project(project)
    end

    if is_task_mother?(task) do
      achieve_children_tasks(task, curr_user_id)
    end

    Services.send_notifs_to_admins_and_attributors(
      curr_user_id,
      "La tâche #{task.title} a été achevée.",
      4
    )
  end

  def put_task_to_ongoing(%Task{} = t, curr_user_id) do
    stage_id = get_ongoing_stage_id_from_project_id!(t.project_id)

    task = get_task_with_card!(t.id)

    Kanban.put_card_to_achieve(task.card, %{"stage_id" => stage_id})
    update_task(task, %{"status_id" => 3})
    broadcast_updated_task({:ok, :updated})
    Services.send_notifs_to_admins_and_attributors(
      curr_user_id,
      "La tâche #{task.title} a été mise en cours.",
      4
    )
  end

  def is_task_primary?(%Task{} = t) do
    is_nil(t.parent_id)
  end

  def count_achieved_primaries(%Project{} = p) do
    p.tasks
    |> Enum.count(fn %Task{} = t ->
      is_nil(t.parent_id) and t.status_id == 5
    end)
  end

  def count_primaries(%Project{} = p) do
    p.tasks |> Enum.count(fn %Task{} = t -> is_nil(t.parent_id) end)
  end

  def update_project_progression(%Project{} = project, attrs) do
    project
    |> Project.update_progression_cs(attrs)
    |> Repo.update()
    |> broadcast_change([:project, :updated])
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  def get_project_with_tasks!(id) do
    tasks_query = from(t in Task)

    project_query =
      from p in Project,
        preload: [tasks: ^tasks_query],
        where: p.id == ^id

    Repo.one!(project_query)
  end

  def get_project_id_by_task!(task_id) do
    query = from t in Task,
            where: t.id == ^task_id,
            select: t.project_id

    Repo.one(query)
  end

  def get_loading_stage_id_from_project_id!(id) do
    stages_query = from(sta in Stage)

    board_query =
      from b in Board,
        preload: [stages: ^stages_query]

    query =
      from p in Project,
        where: p.id == ^id,
        preload: [board: ^board_query]

    stage =
      Repo.one!(query).board.stages
      |> Enum.find(fn %Stage{} = s -> s.status_id == 4 end)

    stage.id
  end

  def get_achieved_stage_id_from_project_id!(id) do
    stages_query = from(sta in Stage)

    board_query =
      from b in Board,
        preload: [stages: ^stages_query]

    query =
      from p in Project,
        where: p.id == ^id,
        preload: [board: ^board_query]

    stage =
      Repo.one!(query).board.stages
      |> Enum.find(fn %Stage{} = s -> s.status_id == 5 end)

    stage.id
  end

  def get_ongoing_stage_id_from_project_id!(id) do
    stages_query = from(sta in Stage)

    board_query =
      from b in Board,
        preload: [stages: ^stages_query]

    query =
      from p in Project,
        where: p.id == ^id,
        preload: [board: ^board_query]

    stage =
      Repo.one!(query).board.stages
      |> Enum.find(fn %Stage{} = s -> s.status_id == 3 end)

    stage.id
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  alias PmLogin.Monitoring.Priority

  @doc """
  Returns the list of priorities.

  ## Examples

      iex> list_priorities()
      [%Priority{}, ...]

  """
  def list_priorities do
    Repo.all(Priority)
  end

  @doc """
  Gets a single priority.

  Raises `Ecto.NoResultsError` if the Priority does not exist.

  ## Examples

      iex> get_priority!(123)
      %Priority{}

      iex> get_priority!(456)
      ** (Ecto.NoResultsError)

  """
  def get_priority!(id), do: Repo.get!(Priority, id)

  @doc """
  Creates a priority.

  ## Examples

      iex> create_priority(%{field: value})
      {:ok, %Priority{}}

      iex> create_priority(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_priority(attrs \\ %{}) do
    %Priority{}
    |> Priority.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a priority.

  ## Examples

      iex> update_priority(priority, %{field: new_value})
      {:ok, %Priority{}}

      iex> update_priority(priority, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_priority(%Priority{} = priority, attrs) do
    priority
    |> Priority.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a priority.

  ## Examples

      iex> delete_priority(priority)
      {:ok, %Priority{}}

      iex> delete_priority(priority)
      {:error, %Ecto.Changeset{}}

  """
  def delete_priority(%Priority{} = priority) do
    Repo.delete(priority)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking priority changes.

  ## Examples

      iex> change_priority(priority)
      %Ecto.Changeset{data: %Priority{}}

  """
  def change_priority(%Priority{} = priority, attrs \\ %{}) do
    Priority.changeset(priority, attrs)
  end

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_primary_tasks(project_id) do
    query =
      from t in Task,
        where: is_nil(t.parent_id) and t.project_id == ^project_id

    Repo.all(query)
  end

  def list_achieved_tasks_today do
    achieved_tasks = list_achieved_tasks()
    curr_date = Services.current_date()

    achieved_tasks
    |> Enum.filter(fn x ->
      curr_date |> NaiveDateTime.to_date() |> Date.day_of_era() ==
        x.achieved_at |> NaiveDateTime.to_date() |> Date.day_of_era()
    end)
  end

  def list_achieved_tasks_this_week do
    achieved_tasks = list_achieved_tasks()
    curr_date = Services.current_date()

    achieved_tasks
    |> Enum.filter(fn x ->
      curr_date |> NaiveDateTime.to_date() |> Date.end_of_week() ==
        x.achieved_at |> NaiveDateTime.to_date() |> Date.end_of_week()
    end)
  end

  def list_achieved_tasks_this_month do
    achieved_tasks = list_achieved_tasks()
    curr_date = Services.current_date()

    achieved_tasks
    |> Enum.filter(fn x ->
      curr_date |> NaiveDateTime.to_date() |> Date.end_of_month() ==
        x.achieved_at |> NaiveDateTime.to_date() |> Date.end_of_month()
    end)
  end

  def naive_to_dt do
    Services.current_date()
    |> NaiveDateTime.to_date()
  end

  def list_achieved_tasks do
    attributor_query = from(attr in User)
    contributor_query = from(contr in User)
    project_query = from(p in Project)

    query =
      from t in Task,
        preload: [
          project: ^project_query,
          attributor: ^attributor_query,
          contributor: ^contributor_query
        ],
        where: not is_nil(t.achieved_at) and is_nil(t.parent_id)

    Repo.all(query)
  end

  def list_statuses_by_id(status_id) do
    query =
      from s in Status,
      where: s.id == ^status_id

    Repo.one(query)
  end

  def get_first_and_third_name do
    ""
  end

  def get_first_and_third_name(title) do
    cond do
      String.length(title) <= 0 ->
        ""

      String.length(title) < 3 and String.length(title) > 0 ->
        title
        |> String.upcase()

      true ->
        title =
          title
          |> String.slice(0, 3)
          |> String.upcase()
          |> String.graphemes()

        [one, _two, three] = title
        one <> three
    end
  end

  def list_priorities(priority_id) do
    query =
      from p in Priority,
      where: p.id == ^priority_id

    Repo.one(query)
  end

  def list_tasks do
    query =
      from t in Task,
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  def list_tools do
    query =
      from t in Tool

    Repo.all(query)
  end

  def get_tool_by_id(tool_id) do
    query =
      from t in Tool,
      where: t.id == ^tool_id

    Repo.one(query)
  end

  def list_tools_group_by_user_id(user_id) do
    query =
      from (tg in ToolGroup),
      join: c in Company,
      on: c.id == tg.company_id,
      join: a in ActiveClient,
      on: a.company_id == c.id,
      where: a.user_id == ^user_id
    Repo.all(query)
  end

  def get_company_by_user_id(user_id) do
    query = from c in Company,
    join: a in ActiveClient,
    on: a.company_id == c.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id
    Repo.one(query)
  end

  def list_company_clients_requests_not_seen_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)
    company_id = get_company_by_user_id(user_id).id

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    where: a.company_id == ^company_id and cr.seen == false
    Repo.all(query)
  end

  def list_clients_requests_not_seen_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.seen == false
    Repo.all(query)
  end

  def search_requests_not_seen(user_id,search) do
    search = "%#{search}%"
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.seen == false and (ilike(cr.title, ^search) or ilike(cr.content, ^search) or ilike(cr.uuid, ^search))
    Repo.all(query)
  end

  def list_company_clients_requests_finished_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)
    company_id = get_company_by_user_id(user_id).id

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    where: a.company_id == ^company_id and cr.finished == true
    Repo.all(query)
  end

  def list_clients_requests_finished_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.finished == true
    Repo.all(query)
  end

  def search_requests_finished(user_id,search) do
    search = "%#{search}%"
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.finished == true and (ilike(cr.title, ^search) or ilike(cr.content, ^search) or ilike(cr.uuid, ^search))
    Repo.all(query)
  end

  def list_company_clients_requests_done_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)
    company_id = get_company_by_user_id(user_id).id

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    where: a.company_id == ^company_id and cr.done == true and cr.finished == false
    Repo.all(query)
  end

  def list_clients_requests_done_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.done == true and cr.finished == false
    Repo.all(query)
  end

  def search_requests_done(user_id,search) do
    search = "%#{search}%"
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.done == true and cr.finished == false and (ilike(cr.title, ^search) or ilike(cr.content, ^search) or ilike(cr.uuid, ^search))
    Repo.all(query)
  end

  def list_company_clients_requests_ongoing_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)
    company_id = get_company_by_user_id(user_id).id

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    where: a.company_id == ^company_id and cr.ongoing == true and cr.done == false and cr.finished == false
    Repo.all(query)
  end

  def list_clients_requests_ongoing_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.ongoing == true and cr.done == false and cr.finished == false
    Repo.all(query)
  end

  def search_requests_ongoing(user_id,search) do
    search = "%#{search}%"
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.ongoing == true and cr.done == false and cr.finished == false
     and (ilike(cr.title, ^search) or ilike(cr.content, ^search) or ilike(cr.uuid, ^search))
    Repo.all(query)
  end

  def list_company_clients_requests_seen_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)
    company_id = get_company_by_user_id(user_id).id

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    where: a.company_id == ^company_id and cr.seen == true and cr.ongoing == false and cr.done == false and cr.finished == false
    Repo.all(query)
  end

  def list_clients_requests_seen_by_clients_user_id(user_id) do
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.seen == true and cr.ongoing == false and cr.done == false and cr.finished == false
    Repo.all(query)
  end

  def search_requests_seen(user_id,search) do
    search = "%#{search}%"
    tool_query = from(t in Tool)
    request_type_query = from(req in RequestType)

    query = from cr in ClientsRequest,
    preload: [
      tool: ^tool_query,
      request_type: ^request_type_query,
    ],
    join: a in ActiveClient,
    on: cr.active_client_id == a.id,
    join: u in User,
    on: u.id == a.user_id,
    where: u.id == ^user_id and cr.seen == true and cr.ongoing == false and cr.done == false and cr.finished == false
     and (ilike(cr.title, ^search) or ilike(cr.content, ^search) or ilike(cr.uuid, ^search))
    Repo.all(query)
  end

  def list_tools_by_group_tool_id(group_id) do
    query =
      from t in Tool,
      where: t.id == ^group_id
    Repo.all(query)
  end

  def list_request_types do
    query =
      from r in RequestType
    Repo.all(query)
  end

  def list_all_tasks_with_card do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      order_by: [desc: t.updated_at]
    Repo.all(query)
  end

  #===========================================#
  # List all client tasks by active client ID #
  #===========================================#
  def list_all_client_tasks_by_active_client_id(active_client_id) do
    task_id = from cr in ClientsRequest,
              where: not is_nil(cr.task_id) and not is_nil(cr.project_id) and cr.active_client_id == ^active_client_id,
              select: cr.task_id

    query = from t in Task,
            where: t.id in ^Repo.all(task_id),
            preload: [:project, :status, :priority],
            order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  def list_all_tasks_with_card_by_active_client_id(active_client_id) do
    card_query = from c in Card,
                 select: c.id

    project_query = from p in Project,
                    where: p.active_client_id == ^active_client_id,
                    select: p.id

    project_id = Repo.all(project_query)

    query = from t in Task,
            where: t.project_id in ^project_id,
            preload: [:project, :status, :priority, card: ^card_query],
            order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # Récupérer la liste des tâches par mise à jour d'ordre décroissant
  def list_tasks_order_by_updated_at do
    query =
      from t in Task,
      where: t.status_id != 5,
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # Récupérer la liste des tâches achevées par mise à jour d'ordre décroissant
  def list_tasks_achieved_order_by_updated_at do
    query =
      from t in Task,
      where: t.status_id == 5,
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # Récupérer la liste des tâches en passant en paramètre la status
  def list_tasks_by_month(status_id, month) do
    query =
      from t in Task,
      where: t.status_id == ^status_id

    result = Repo.all(query)

    Enum.filter(result,
      fn result ->
        naive_dt = result.updated_at

        naive_dt.month == month
      end
    )
  end

  # Récupérer la liste des tâches par status_id
  def list_tasks_by_status_id(status_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id == ^status_id

    Repo.all(query)
  end

  # Récupérer la liste des tâches par task_id et project_id
  def list_tasks_by_project_and_task!(task_id, project_id) do
    query = from t in Task,
            where: t.id == ^task_id and t.project_id == ^project_id,
            select: t.status_id

    Repo.one(query)
  end

  # Récupérer la liste des tâches par task_id
  def list_tasks_by_project_and_task!(task_id) do
    query = from t in Task,
            where: t.id == ^task_id,
            select: t.status_id

    Repo.one(query)
  end

  # Récupérer la liste des tâches par contributor_id
  def list_tasks_by_contributor_id(contributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id != 5 and t.contributor_id == ^contributor_id

    Repo.all(query)
  end

  def list_tasks_by_status_id_and_contributor_id(status_id, contributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id == ^status_id and t.contributor_id == ^contributor_id

    Repo.all(query)
  end

  def list_tasks_by_status_id_and_attributor_id(status_id, attributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id == ^status_id and t.attributor_id == ^attributor_id

    Repo.all(query)
  end

  def list_tasks_by_contributor_id(contributor_id, attributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.contributor_id == ^contributor_id and t.attributor_id == ^attributor_id

    Repo.all(query)
  end

  def list_tasks_by_attributor_id(attributor_id, contributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.attributor_id == ^attributor_id and t.contributor_id == ^contributor_id

    Repo.all(query)
  end

  # Récupérer la liste des tâches sans contributeurs
  def list_tasks_without_contributor do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id != 5 and is_nil(t.contributor_id)

    Repo.all(query)
  end

  # Récupérer la liste des tâches filtrer par date de début
  def list_tasks_filtered_by_date(date) do
    query =
      from t in Task,
      where: t.status_id != 5 and t.date_start <= ^date,
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # Récupérer la listes des tâches mise à jour aujourd'hui
  def list_tasks_filtered_by_date_today do
    # Récupérer la date actuelle et le changer en chaine de caractères
    date_today =
      Date.utc_today()
      |> Date.to_string()

    # IO.inspect(date_today)

    query =
      from t in Task,
      where: t.status_id != 5,
      order_by: [desc: t.updated_at]

    result = Repo.all(query)

    # Filtrer les résultats
    # Récupérer les tâches qui sont modifiés à la date actuelle
    Enum.filter(result,
      fn result ->
        string = NaiveDateTime.to_string(result.updated_at)
        String.contains?(string, date_today)
      end
    )
  end

  # Récupérer la liste des tâches effectuées hier
  def list_tasks_updated_yesterday do
    # Récupérer la date actuelle et le changer en chaine de caractères
    date_today = Date.utc_today()

    date_yesterday =
      date_today
      |> Date.add(-1)
      |> Date.to_string()

    # IO.inspect(date_yesterday)

    query =
      from t in Task,
      where: t.status_id != 5,
      order_by: [desc: t.updated_at]

    result = Repo.all(query)

    # Filtrer les résultats
    # Récupérer les tâches qui sont modifiés à la date actuelle
    Enum.filter(result,
      fn result ->
        string = NaiveDateTime.to_string(result.updated_at)
        String.contains?(string, date_yesterday)
      end
    )
  end

  # Récupérer la liste des tâches effectuées il y a un mois
  def list_tasks_updated_a_month_ago do
    # Récupérer la date actuelle et le changer en chaine de caractères
    date_today = NaiveDateTime.local_now()

    # month_ago =
    #   NaiveDateTime.new!(date_today.year, date_today.month - 1, date_today.day, 23, 59, 59)

    month_ago = NaiveDateTime.add(date_today, -60*60*24*30, :second)

    query =
      from t in Task,
      where: t.status_id != 5 and t.updated_at <= ^month_ago,
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # Différence entre la date de mise à jour et la date locale
  def difference_between_updated_at_and_local_time(naive_dt) do
    # Récupérer le fuseau horaire de l'utilisateur
    # Convertir le fuseau horaire saisie en heure locale
    time =
      NaiveDateTime.local_now()
      |> NaiveDateTime.to_time()

    # Convertir le fuseau horaire saisie en heure locale
    naive_dt = NaiveDateTime.to_time(naive_dt)

    # Calculer la différence entre la date de mise à jour et l'heure locale
    seconds_ago = Time.diff(time, naive_dt, :second)

    cond do

      # seconds_ago > 59 and seconds_ago < 3600 -> "#{trunc(seconds_ago / 60)} minute(s)"
      # seconds_ago > 3599 and seconds_ago < 86400 -> "#{trunc(seconds_ago / 3600)} heure(s)"
      # seconds_ago > 86399 and seconds_ago < 2592000 -> "#{trunc(seconds_ago / 86400)} jour(s)"
      # seconds_ago > 2591999 and seconds_ago < 31104000 -> "#{trunc(seconds_ago / 2592000)} mois"
      # seconds_ago > 31103999 -> "#{trunc(seconds_ago / 31104000)} an(s)"
      # true -> "#{seconds_ago} secondes"

      # On affiche la seconde
      seconds_ago >= 0 and seconds_ago < 60 ->
        if seconds_ago > 1 do
          "Il y a #{seconds_ago} secondes"
        else
          "Il y a #{seconds_ago} seconde"
        end

      # On affiche la minute
      seconds_ago >= 60 and seconds_ago < 3600 ->
        # On convertit la minute en integer
        seconds_ago = Integer.floor_div(seconds_ago, 60)

        if seconds_ago > 1 do
          "Il y a #{seconds_ago} minutes"
        else
          "Il y a #{seconds_ago} minute"
        end

      # On affiche l'heure
      seconds_ago >= 3600 and seconds_ago < 86400 ->
        seconds_ago = Integer.floor_div(seconds_ago, 3600)

        if seconds_ago > 1 do
          "Il y a #{seconds_ago} heures"
        else
          "Il y a #{seconds_ago} heure"
        end

      seconds_ago >= 86400 and seconds_ago < 2592000 ->
        seconds_ago = Integer.floor_div(seconds_ago, 86400)

        if seconds_ago > 1 do
          "Il y a #{seconds_ago} jour"
        else
          "Il y a #{seconds_ago} jours"
        end

      true -> "#{seconds_ago} secondes"
    end
  end

  def show_hidden_tasks(project_id) do
    query =
      from t in Task,
        where: t.hidden and t.project_id == ^project_id

    Repo.update_all(query, set: [hidden: false])
    |> broadcast_hidden_change([:tasks, :shown])
  end

  def restore_archived_tasks(list_ids) do
    query =
      from t in Task,
        where: t.id in ^list_ids

    Repo.update_all(query, set: [hidden: false])
    |> broadcast_hidden_change([:tasks, :shown])
  end

  def list_hidden_tasks(project_id) do
    query =
      from t in Task,
        where: t.hidden and t.project_id == ^project_id,
        preload: [contributor: ^from(u in User)]

    Repo.all(query)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  def get_task_with_card!(id) do
    card_query = from(c in Card)

    query =
      from t in Task,
        where: t.id == ^id,
        preload: [card: ^card_query]

    Repo.one!(query)
  end

  def get_status_by_task!(task_id) do
    query = from t in Task,
            where: t.id == ^task_id,
            select: t.status_id

    Repo.one(query)
  end

  # def set_parent do
  #
  # end

  def get_task_with_parent!(id) do
    parent_card_query = from(c in Card)

    parent_query =
      from p in Task,
        preload: [card: ^parent_card_query]

    card_query = from(ca in Card)

    query =
      from t in Task,
        where: t.id == ^id,
        preload: [parent: ^parent_query, card: ^card_query]

    Repo.one!(query)
  end

  def get_task_with_children!(id) do
    card_query = from(c in Card)

    query =
      from t in Task,
        where: t.id == ^id,
        preload: [children: :children, card: ^card_query]

    Repo.one!(query)
  end

  def is_a_child?(%Task{} = t) do
    !is_nil(t.parent_id)
  end

  def update_mother_task_progression(%Task{} = child, curr_user_id) do
    t = get_task_with_children!(child.parent_id)
    up_rate = 1 / length(t.children) * 100
    prog = t.progression + trunc(up_rate)
    update_mother_progression(t, %{"progression" => prog})

    # round progression to 0 or 100 if all children are achieved or none
    moth = get_task_with_children!(t.id)
    update_mother_progression(moth, %{"progression" => round_mother_progression(t.id)})

    rounded_moth = get_task_with_children!(t.id)
    # IO.inspect moth.project_id
    # IO.inspect moth.card
    # IO.inspect moth.card_id

    # IO.inspect moth.progression

    if rounded_moth.progression == 100 do
      stage_id = get_loading_stage_id_from_project_id!(moth.project_id)
      Kanban.put_mothercard_to_loading(moth.card, %{"stage_id" => stage_id})
      update_task(moth, %{"status_id" => 4})

      Services.send_notifs_to_admins_and_attributors(
        curr_user_id,
        "Tâche #{moth.title} a été placée automatiquement \"en cours\" car toutes ses tâches filles ont été achevées",
        7
      )
    end
  end

  def substract_mother_task_progression_when_removing_child_from_achieved(%Task{} = child) do
    t = get_task_with_children!(child.parent_id)
    down_rate = 1 / length(t.children) * 100
    prog = t.progression - trunc(down_rate)
    update_mother_progression(t, %{"progression" => prog})

    # round progression to 0 or 100 if all children are achieved or none
    moth = get_task_with_children!(t.id)
    update_mother_progression(moth, %{"progression" => round_mother_progression(t.id)})
  end

  def substract_mother_task_progression_when_creating_child(%Task{} = child) do
    t = get_task_with_children!(child.parent_id)
    nb_children = length(t.children)
    down_rate = 1 / nb_children * 100
    prog = t.progression - trunc(down_rate)
    update_mother_progression(t, %{"progression" => prog})

    # round progression to 0 or 100 if all children are achieved or none
    moth = get_task_with_children!(t.id)
    update_mother_progression(moth, %{"progression" => round_mother_progression(t.id)})
  end

  def get_task_with_status!(id) do
    status_query = from(s in Status)

    query =
      from t in Task,
        preload: [status: ^status_query],
        where: t.id == ^id

    Repo.one!(query)
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  # REAL TASK CREATION WITH CARD

  def cards_list_primary_tasks(old_list) do
    old_list |> Enum.filter(fn card -> is_nil(card.task.parent_id) end) |> Enum.filter(fn card -> card.task.status_id > 0 end)
  end

  def spawn_task(%Planified{} = planified) do
    planified_map = Map.from_struct(planified)
    now = NaiveDateTime.local_now()

    planned_deadline =
      NaiveDateTime.add(now, 3600 * planified_map[:estimated_duration])
      |> NaiveDateTime.to_date()

    params = %{
      title: planified_map[:description],
      without_control: planified_map[:without_control],
      attributor_id: planified_map[:attributor_id],
      contributor_id: planified_map[:contributor_id],
      project_id: planified_map[:project_id],
      date_start: now |> NaiveDateTime.to_date(),
      estimated_duration: planified_map[:estimated_duration],
      deadline: planned_deadline
    }

    IO.inspect(params)

    {:ok, task} = create_real_task(params)

    current_project = get_project!(planified_map[:project_id])
    board = Kanban.get_board!(current_project.board_id)

    primary_stages =
      board.stages
      |> Enum.map(fn %Kanban.Stage{} = stage ->
        struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

    primary_board = struct(board, stages: primary_stages)

    this_project = primary_board.project
    substract_project_progression_when_creating_primary(this_project)

    [head | _] = primary_board.stages
    Kanban.create_card(%{name: task.title, stage_id: head.id, task_id: task.id})

    Services.send_notifs_to_admins_and_attributors(
      planified_map[:attributor_id],
      "Tâche nouvellement créee du nom de #{task.title} par #{Login.get_user!(planified_map[:attributor_id]).username} dans le projet #{this_project.title}.",
      5
    )

    if not is_nil(planified_map[:contributor_id]) do
      Services.send_notif_to_one(
        planified_map[:attributor_id],
        planified_map[:contributor_id],
        "#{Login.get_user!(planified_map[:contributor_id]).username} a été assigné à la tâche #{task.title} dans le projet #{this_project.title} par #{Login.get_user!(planified_map[:attributor_id]).username}",
        6
      )

      Services.send_notifs_to_admins(
        planified_map[:attributor_id],
        "#{Login.get_user!(planified_map[:contributor_id]).username} a été assigné à la tâche #{task.title} dans le projet #{this_project.title} par #{Login.get_user!(planified_map[:attributor_id]).username}",
        6
      )
    end
  end

  def create_real_task(attrs \\ %{}) do
    %Task{}
    |> Task.real_creation_changeset(attrs)
    |> Repo.insert()
  end

  #

  def create_task_with_card(attrs \\ %{}) do
    %Task{}
    |> Task.create_changeset(attrs)
    |> Repo.insert()
  end

  def create_secondary_task(attrs \\ %{}) do
    %Task{}
    |> Task.secondary_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.update_changeset(attrs)
    |> Repo.update()
  end

  def hide_task(%Task{} = task) do
    task
    |> Task.hidden_changeset(%{"hidden" => true})
    |> Repo.update()
    |> broadcast_hidden_change([:task, :hidden])
  end

  def round_project_progression(id) do
    project = get_project_with_tasks!(id)
    len = count_primaries(project)
    achieved = count_achieved_primaries(project)

    case achieved do
      ^len -> 100
      0 -> 0
      _ -> project.progression
    end
  end

  def round_mother_progression(id) do
    task = get_task_with_children!(id)
    len = length(task.children)

    achieved = count_achieved_children_tasks(task)

    case achieved do
      ^len -> 100
      0 -> 0
      _ -> task.progression
    end
  end

  def count_achieved_children_tasks(%Task{} = mother) do
    mother.children |> Enum.count(fn %Task{} = t -> t.status_id == 5 end)
  end

  def update_mother_progression(%Task{} = task, attrs) do
    task
    |> Task.update_moth_prg_changeset(attrs)
    |> Repo.update()
    |> broadcast_change([:mother, :updated])
  end

  def update_task_status(%Task{} = task, attrs) do
    task
    |> Task.update_status_changeset(attrs)
    |> Repo.update()
  end

  def update_task_progression(%Task{} = task, attrs) do
    task
    |> Task.update_progression_changeset(attrs)
    |> Repo.update()
  end

  def broadcast_status_change(tuple) do
    tuple
    |> broadcast_change([:status, :updated])
  end

  def broadcast_updated_task(tuple), do: tuple |> broadcast_change([:task, :updated])

  def broadcast_progression_change(tuple), do: tuple |> broadcast_change([:progression, :updated])

  def broadcast_deleted_task({:ok, :deleted}), do: {:ok, :deleted} |> broadcast_change([:task, :deleted])

  def broadcast_archived_task({:ok, :archived}), do: {:ok, :archived} |> broadcast_change([:task, :archived])

  def broadcast_restored_task({:ok, :restored}), do: {:ok, :restored} |> broadcast_change([:task, :restored])

  def broadcast_clients_requests(tuple), do: tuple |> broadcast_change([:request, :created])

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  alias PmLogin.Monitoring.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  def list_comments_by_task_id(task_id) do
    query =
      from c in Comment,
        where: c.task_id == ^task_id,
        order_by: [asc: :inserted_at]

    Repo.all(query)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  def post_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.create_changeset(attrs)
    |> Repo.insert()

    # |> broadcast_change([:comment, :posted])
  end

  def broadcast_com(tuple) do
    broadcast_change(tuple, [:comment, :posted])
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  def update_comment_files(%Comment{} = comment, attrs) do
    comment
    |> Comment.upload_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def list_project_contributors(%Board{} = board) do
    contributor_ids =
      board.project.tasks
      |> Enum.filter(fn task -> not is_nil(task.contributor_id) end)
      |> Enum.map(fn task -> task.contributor_id end)
      |> Enum.uniq()

    for id <- contributor_ids do
      Login.get_user!(id)
    end
  end

  def list_project_attributors(%Board{} = board) do
    attributors_ids =
      board.project.tasks
      |> Enum.filter(fn task -> not is_nil(task.attributor_id) end)
      |> Enum.map(fn task -> task.attributor_id end)
      |> Enum.uniq()

    for id <- attributors_ids do
      Login.get_user!(id)
    end
  end

  def list_my_unachieved_tasks(my_id) do
    project_query = from(p in Project)

    query =
      from t in Task,
        preload: [project: ^project_query],
        where: t.contributor_id == ^my_id and is_nil(t.achieved_at),
        order_by: [desc: :priority_id]

    Repo.all(query)
  end

  def list_my_achieved_tasks(my_id) do
    query =
      from t in Task,
        where: t.contributor_id == ^my_id and not is_nil(t.achieved_at) and is_nil(t.parent_id)

    Repo.all(query)
  end

  def my_onboard_achieved(my_id) do
    project_query = from(p in Project)
    attributor_query = from(u in User)

    query =
      from t in Task,
        where: t.contributor_id == ^my_id and not is_nil(t.achieved_at) and is_nil(t.parent_id),
        order_by: [desc: :achieved_at],
        preload: [project: ^project_query, attributor: ^attributor_query]

    Repo.all(query)
  end

  def duration_diff(%Task{} = t) do
    cond do
      t.performed_duration > t.estimated_duration ->
        "(+ #{t.performed_duration - t.estimated_duration} #{if t.estimated_duration  > 1, do: "minutes", else: "minute"})"

      t.performed_duration == t.estimated_duration ->
        "(= #{t.performed_duration - t.estimated_duration} #{if t.estimated_duration  > 1, do: "minutes", else: "minute"})"

      t.performed_duration < t.estimated_duration ->
        "(- #{t.estimated_duration - t.performed_duration} #{if t.estimated_duration  > 1, do: "minutes", else: "minute"})"
    end
  end

  def duration_diff_color_class(%Task{} = t) do
    cond do
      t.performed_duration > t.estimated_duration -> "durr__diff__gt"
      t.performed_duration == t.estimated_duration -> "durr__diff__eq"
      t.performed_duration < t.estimated_duration -> "durr__diff__lt"
    end
  end

  def date_diff(%Task{} = t) do
    cond do
      Date.diff(t.achieved_at, t.deadline) > 0 ->
        "#{Date.diff(t.achieved_at, t.deadline)} jours de retard"

      Date.diff(t.achieved_at, t.deadline) == 0 ->
        "Achevée le jour même"

      Date.diff(t.achieved_at, t.deadline) < 0 ->
        "#{Date.diff(t.deadline, t.achieved_at)} jours d'avance"
    end
  end

  def date_diff_color_class(%Task{} = t) do
    cond do
      Date.diff(t.achieved_at, t.deadline) > 0 -> "dt_durr__diff__gt"
      Date.diff(t.achieved_at, t.deadline) == 0 -> "dt_durr__diff__eq"
      Date.diff(t.achieved_at, t.deadline) < 0 -> "dt_durr__diff__lt"
    end
  end

  def my_achieved_length(my_id) do
    list_my_achieved_tasks(my_id)
    |> length
  end

  def my_unachieved_length(my_id) do
    list_my_unachieved_tasks(my_id)
    |> length
  end

  def list_my_near_unachieved_tasks(my_id) do
    today = NaiveDateTime.local_now() |> NaiveDateTime.to_date()
    range = 0..7
    tasks = list_my_unachieved_tasks(my_id)
    tasks |> Enum.filter(fn task -> Date.diff(task.deadline, today) in range end)
  end

  def list_my_past_unachieved_tasks(my_id) do
    today = NaiveDateTime.local_now() |> NaiveDateTime.to_date()
    tasks = list_my_unachieved_tasks(my_id)
    tasks |> Enum.filter(fn task -> Date.diff(task.deadline, today) < 0 end)
  end

  def warning_text(task) do
    today = NaiveDateTime.local_now() |> NaiveDateTime.to_date()

    cond do
      Date.diff(task.deadline, today) == 7 -> "dans une semaine"
      Date.diff(task.deadline, today) in 2..6 -> "dans #{Date.diff(task.deadline, today)} jours"
      Date.diff(task.deadline, today) == 1 -> "demain"
      Date.diff(task.deadline, today) == 0 -> "aujourd'hui"
      true -> ""
    end
  end

  def list_last_seven_days(my_id) do
    achieved = list_my_achieved_tasks(my_id)

    today =
      NaiveDateTime.local_now()
      |> NaiveDateTime.to_date()

    Enum.map(1..7, fn x -> Date.add(today, -x) end)
    |> Enum.map(fn date ->
      [date, Enum.count(achieved, fn task -> Date.compare(date, task.achieved_at) == :eq end)]
    end)
    |> Enum.map(fn [date, number] -> [simple_date_format(date), number] end)
    |> Enum.reverse()
  end

  # def achieved_number_by_day(list) do

  # end

  #New function
  def list_tasks_ismajor_true do
    query = from t in Task,
          where: t.is_major == true,
          select: t
    Repo.all(query)
  end

  def list_tasks_ismajor_false do
    query = from t in Task,
          where: t.is_major == false,
          select: t
    Repo.all(query)
  end

  def get_tasks_by_id(id) do
    query = from t in Task,
            where: t.id == ^id,
            select: t
    Repo.all(query)
  end

  def list_tasks_by_date(date_start, date_end) do
    query =  from t in Task,
            where: t.date_start >= ^date_start and t.deadline <= ^date_end,
            select: t
    Repo.all(query)
  end
  def list_tasks_by_date_ismajor_true(date_start, date_end) do
    query = from t in Task,
            where: t.is_major == true and t.date_start >= ^date_start and t.deadline <= ^date_end,
            select: t
    Repo.all(query)
  end
  def list_tasks_by_date_ismajor_false(date_start, date_end) do
    query = from t in Task,
            where: t.is_major == false and t.date_start >= ^date_start and t.deadline <= ^date_end,
            select: t
    Repo.all(query)
  end


  def list_projects_by_clients_user_id(con_id) do
    query =
      from p in Project,
        join: a in ActiveClient,
        on: p.active_client_id == a.id,
        join: u in User,
        on: u.id == a.user_id,
        where: u.id == ^con_id,
        order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_projects_ongoing_by_clients_user_id(con_id) do
    query =
      from p in Project,
        join: a in ActiveClient,
        on: p.active_client_id == a.id,
        join: u in User,
        on: u.id == a.user_id,
        where: u.id == ^con_id and p.status_id != 5,
        order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_project_by_status_and_user_client!(status_id,con_id) do
    query = from p in Project,
            join: a in ActiveClient,
            on: p.active_client_id == a.id,
            join: u in User,
            on: u.id == a.user_id,
            where: p.status_id == ^status_id and u.id == ^con_id,
            order_by: [desc: :inserted_at]

    Repo.all(query)
  end

  def list_project_by_title_and_user_client!(project_title,con_id) do
    project_search = "%#{project_title}%"

    query = from p in Project,
            join: a in ActiveClient,
            on: p.active_client_id == a.id,
            join: u in User,
            on: u.id == a.user_id,
            where: (ilike(p.title, ^project_search) or ilike(p.description, ^project_search)) and u.id == ^con_id,
            order_by: [desc: :inserted_at]

    Repo.all(query)
  end



  # List all the tasks recently in control
  def list_tasks_recently_in_control do
    card_query =
      from c in Card,
      select: c.id

    query =
      from t in Task,
      where: t.status_id ==^4 and t.updated_at >= from_now(-5, "minute") and t.updated_at < ^DateTime.utc_now(),
      preload: [:project, :status, :priority, card: ^card_query],
      order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  # List all the upcoming deadline tasks
  def list_tasks_with_upcoming_deadline do
    card_query =
      from c in Card,
      select: c.id

    query =
      from t in Task,
      # where: t.deadline > ^DateTime.utc_now() and (t.deadline <= from_now(1, "day") or t.deadline <= from_now(10, "minute")),
      where: t.deadline > ^DateTime.utc_now() and t.deadline <= from_now(1, "day"),
      preload: [:project, :status, :priority, card: ^card_query],
      order_by: [desc: t.deadline]

    Repo.all(query)
  end

  # Return tasks list according to project
  def list_tasks_by_project(project_id) do
    card_query =
            from c in Card,
            select: c.id

    query = from t in Task,
            preload: [:project, :status, :priority, :clients_request, card: ^card_query],
            where: t.project_id == ^project_id,
            order_by: [desc: t.inserted_at]
    Repo.all(query)
  end

  # Return tasks list according to priority
  def list_tasks_by_priority(priority_id) do
    card_query =
            from c in Card,
            select: c.id

    query = from t in Task,
            preload: [:project, :status, :priority, card: ^card_query],
            where: t.priority_id == ^priority_id
    Repo.all(query)
  end

  # Return tasks list according to attributor
  def list_tasks_by_attributor(attributor_id) do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id != 5 and t.attributor_id == ^attributor_id

    Repo.all(query)
  end

  # Return tasks list without any attributor
  def list_tasks_without_attributor do
    card_query =
      from c in Card,
        select: c.id

    query =
      from t in Task,
      preload: [:project, :status, :priority, card: ^card_query],
      where: t.status_id != 5 and is_nil(t.attributor)

    Repo.all(query)
  end

  # Multi filter request
  def list_tasks_by_project_status_priority_attributor_contributor_customer(project_id, status_id, priority_id, attributor_id, contributor_id, customer_id) do
    card_query =
      from c in Card,
      select: c.id
    # card_ids = Repo.all(card_query)

    project_query =
      case project_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.project_id == ^project_id
      end

    status_query =
      case status_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.status_id == ^status_id
      end

    priority_query =
      case priority_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.priority_id == ^priority_id
      end

    attributor_query =
      case attributor_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        "-1"   -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.attributor_id != 5 and is_nil(t.attributor_id)
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.attributor_id == ^attributor_id
      end

    contributor_query =
      case contributor_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        "-1"   -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.contributor_id != 5 and is_nil(t.contributor_id)
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.contributor_id == ^contributor_id
      end

    customer_query =
      case customer_id do
        "9000" -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: true
        "-1"   -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.customer_id != 5 and is_nil(t.customer_id)
        _      -> from t in Task,
                    preload: [:project, :status, :priority, card: ^card_query],
                    where: t.customer_id == ^customer_id
      end


    # queries = [project_query, status_query, priority_query, attributor_query, contributor_query, customer_query]
    # intersect_query = Enum.reduce(queries, &intersect/2)

    intersect_query = from t in Task,
            intersect: ^project_query,
            intersect: ^status_query,
            intersect: ^priority_query,
            intersect: ^attributor_query,
            intersect: ^contributor_query,
            intersect: ^customer_query

    Repo.all(intersect_query)

  end

  def is_late(%Task{} = t) do
    today = Date.utc_today()
    t.deadline
    Date.diff(t.deadline,today)
  end

  def get_clients_request_by_id(id) do
    user_query = from(u in User)
    active_client_query = from ac in ActiveClient,
        preload: [user: ^user_query]

    request_type_query = from(rt in RequestType)

    tasks_query = from t in Task,
      where: t.clients_request_id == ^id

    tool_query = from(t in Tool)
    query = from cr in ClientsRequest,
      preload: [active_client: ^active_client_query,request_type: ^request_type_query,tool: ^tool_query, tasks: ^tasks_query],
      where: cr.id == ^id
      Repo.one(query)
  end

  # TASK HISTORY
  # Create task history
  def create_task_history(attrs \\ %{}) do
    %TaskHistory{}
    |> TaskHistory.changeset(attrs)
    |> Repo.insert()
  end

  # Update task history reason
  def update_task_history_reason(%TaskHistory{} = task_history, attrs) do
    task_history
    |> TaskHistory.update_reason_changeset(attrs)
    |> Repo.update()
  end


  # Get the latests tasks without reason but must have one
  def get_last_history_task_with_reason_to_be_checked(project_id, user_id) do
    query = from th in TaskHistory,
            join: t in Task,
            on: t.id == th.task_id,
            join: p in Project,
            on: p.id == t.project_id,
            where: p.id == ^project_id and th.intervener_id == ^user_id,
            preload: [:task, :intervener, :status_from, :status_to],
            order_by: [desc: :inserted_at],
            limit: 1,
            select: th
    Repo.all(query)
  end

  # List the history of a given project
  def list_history_tasks_by_project(project_id) do
    query = from th in TaskHistory,
            join: t in Task,
            on: t.id == th.task_id,
            join: p in Project,
            on: p.id == t.project_id,
            where: p.id == ^project_id,
            preload: [:task, :intervener, :status_from, :status_to],
            order_by: [desc: :inserted_at],
            select: th
    Repo.all(query)
  end

  def list_history_tasks_by_task_id(task_id) do
    query = from th in TaskHistory,
            join: t in Task,
            on: t.id == th.task_id,
            join: p in Project,
            on: p.id == t.project_id,
            where: t.id == ^task_id,
            preload: [:task, :intervener, :status_from, :status_to],
            order_by: [desc: :inserted_at],
            select: th
    Repo.all(query)
  end

  # List the history of a given task
  def list_history_tasks_by_id(task_id) do
    query = from th in TaskHistory,
            join: t in Task,
            on: t.id == th.task_id,
            where: t.id == ^task_id,
            preload: [:task, :intervener, :status_from, :status_to],
            order_by: [desc: :inserted_at],
            select: th
    Repo.all(query)
  end

  # List all task history
  def list_history_tasks do
    query = from th in TaskHistory,
            preload: [:task, :intervener, :status_from, :status_to],
            order_by: [desc: :tracing_date],
            select: th
    Repo.all(query)
  end

  # Get a task history
  def get_task_history!(task_history_id) do
    query = from th in TaskHistory,
            where: th.id == ^task_history_id,
            preload: [:task, :intervener, :status_from, :status_to]
    Repo.one(query)
  end

  def get_task_by_id(id) do
    parent_query = from(tp in Task)

    children_query = from tc in Task,
      where: tc.parent_id == ^id

    status_query = from(s in Status)

    priority_query = from(s in Priority)


    user_query = from(u in User)
    active_client_query = from ac in ActiveClient,
        preload: [user: ^user_query]
    client_request_query = from cr in ClientsRequest,
        preload: [active_client: ^active_client_query]

    query = from t in Task,
    preload: [parent: ^parent_query,children: ^children_query,status: ^status_query,priority: ^priority_query,clients_request: ^client_request_query],
    where: t.id == ^id

    Repo.one(query)

  end

  def get_card_by_task_id(id) do
    stage_query = from(s in Stage)
    task_query = from(t in Task)

    query = from c in Card,
      preload: [stage: ^stage_query, task: ^task_query],
      where: c.task_id == ^id
    Repo.one(query)
  end

end
