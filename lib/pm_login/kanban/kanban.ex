defmodule PmLogin.Kanban do
  import Ecto.Query

  alias PmLogin.Repo
  alias PmLogin.Kanban.{Board, Stage, Card}
  alias PmLogin.Monitoring.{Task, Status, Priority, Comment, Project}
  alias PmLogin.Login.User
  alias PmLogin.Services.{ActiveClient, Company}

  def get_board!(board_id) do
    parent_query = from tsk in Task
    contributor_query = from c in User
    attributor_query = from u in User

    task_query = from t in Task,
                preload: [attributor: ^attributor_query, contributor: ^contributor_query, parent: ^parent_query, children: :children]

    stage_query =
      from s in Stage,
        order_by: s.position,
        preload: [
          cards:
            ^from(c in Card,
              preload: [task: ^task_query],
              order_by: :position
            )
        ]

      ac_user_query = from ac_u in User
      company_query = from comp in Company
      active_client_query = from ac in ActiveClient,
                            preload: [company: ^company_query,user: ^ac_user_query]
      p_t_children_query = from cdren in Task
      p_tasks_query = from tas in Task,
                      preload: [children: ^p_t_children_query]
      project_query = from pro in Project,
                      preload: [tasks: ^p_tasks_query, active_client: ^active_client_query]


      board_query =
        from b in Board,
          preload: [stages: ^stage_query, project: ^project_query],
          where: b.id == ^board_id

      Repo.one!(board_query)
    # Board
    # |> preload(stages: ^stage_query)
    # |> first()
    # |> Repo.one!()
  end

  def get_board_by_attributor!(board_id, attributor_id) do
    parent_query = from tsk in Task
    contributor_query = from c in User
    attributor_query = from u in User

    task_query = from t in Task,
                preload: [attributor: ^attributor_query, contributor: ^contributor_query, parent: ^parent_query, children: :children],
                where: t.attributor_id == ^attributor_id

    stage_query =
      from s in Stage,
        order_by: s.position,
        preload: [
          cards:
            ^from(c in Card,
              preload: [task: ^task_query],
              order_by: :position
            )
        ]

      ac_user_query = from ac_u in User
      company_query = from comp in Company
      active_client_query = from ac in ActiveClient,
                            preload: [company: ^company_query,user: ^ac_user_query]
      p_t_children_query = from cdren in Task
      p_tasks_query = from tas in Task,
                      preload: [children: ^p_t_children_query]
      project_query = from pro in Project,
                      preload: [tasks: ^p_tasks_query, active_client: ^active_client_query]


      board_query =
        from b in Board,
          preload: [stages: ^stage_query, project: ^project_query],
          where: b.id == ^board_id

      Repo.one!(board_query)

  end

  def create_board(attrs) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  def get_stage!(id) do
    Repo.get(Stage, id)
  end

  def get_stage_by_position!(board_id, position) do
    query = from s in Stage, where: s.position == ^position and s.board_id == ^board_id
    Repo.one!(query)
  end

  def create_stage(attrs) do
    %Stage{}
    |> Stage.create_changeset(attrs)
    |> Repo.insert()
  end

  def create_stage_from_project(attrs) do
    %Stage{}
    |> Stage.create_from_project_changeset(attrs)
    |> Repo.insert()
  end

  def update_stage(stage, attrs) do
    stage
    |> Stage.update_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:stage, :updated])
  end

  def get_card_from_modal!(id) do
    contributor_query = from c in User
    priority_query = from p in Priority
    status_query = from s in Status
    attributor_query = from u in User

    task_query = from t in Task,
                preload: [attributor: ^attributor_query, status: ^status_query,
                priority: ^priority_query, contributor: ^contributor_query]

    query = from c in Card,
            preload: [task: ^task_query],
            where: c.id == ^id

    Repo.one!(query)
  end

  def get_card!(id) do
    Repo.get(Card, id)
  end

  def get_all_card() do
    contributor_query = from c in User
    priority_query = from p in Priority
    status_query = from s in Status
    attributor_query = from u in User

    task_query = from t in Task,
                preload: [attributor: ^attributor_query, status: ^status_query,
                priority: ^priority_query, contributor: ^contributor_query]

    query = from c in Card,
            preload: [task: ^task_query],
            select: c

    Repo.all(query)
  end

  def get_card_for_comment_limit!(id, number) do
    poster_query = from p in User

    comments_query = from c in Comment,
                      preload: [poster: ^poster_query],
                    order_by: [desc: :inserted_at],
                    limit: ^number

    # comments_query_asc = from cq in subquery(comments_query), order_by: [asc: :inserted_at]

    task_query = from t in Task,
                  preload: [comments: ^comments_query]

    query = from crd in Card,
            preload: [task: ^task_query],
            where: crd.id == ^id

    Repo.one!(query)
  end

  def get_card_for_comment!(id) do
    poster_query = from p in User

    comments_query = from c in Comment,
                      preload: [poster: ^poster_query],
                    order_by: [asc: :inserted_at]

    task_query = from t in Task,
                  preload: [comments: ^comments_query]

    query = from crd in Card,
            preload: [task: ^task_query],
            where: crd.id == ^id

    Repo.one!(query)
  end

  def create_card(attrs) do
    %Card{}
    |> Card.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:card, :created])
  end

  def update_card(card, attrs) do
    card
    |> Card.update_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:card, :updated])
  end


  def put_mothercard_to_loading(card, attrs) do
    card
    |> Card.update_mother_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:card, :updated])
  end

  def put_childcard_to_achieve(card, attrs) do
    card
    |> Card.update_mother_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:card, :updated])
  end

  def put_card_to_achieve(card, attrs) do
    card
    |> Card.update_stage_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:card, :updated])
  end

  def remove_mother_card_from_achieve(card, attrs) do
    card
    |> Card.update_mother_changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:card, :updated])
  end

  @topic "board"

  def subscribe do
    Phoenix.PubSub.subscribe(PmLogin.PubSub, @topic)
  end

  defp notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(PmLogin.PubSub, @topic, {__MODULE__, event, result})

    Phoenix.PubSub.broadcast(
      PmLogin.PubSub,
      @topic <> "#{result.id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
