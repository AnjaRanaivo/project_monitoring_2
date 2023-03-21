defmodule PmLoginWeb.Project.AllTasksLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Login
  alias PmLogin.Login.{User}
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.{Task, Priority}
  alias PmLogin.Services
  alias PmLogin.Kanban


  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    statuses = Monitoring.list_statuses()

    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})

    priorities = Monitoring.list_priorities()
    list_priorities = Enum.map(priorities, fn %Priority{} = p -> {p.title, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)


    socket =
      socket
      |> assign(
        curr_user_id: curr_user_id,
        tasks: Monitoring.list_all_tasks_with_card(),
        statuses: statuses,
        tasks_not_achieved: Monitoring.list_tasks_attributed_not_achieved(curr_user_id),
        is_attributor: Monitoring.is_attributor?(curr_user_id),
        is_admin: Monitoring.is_admin?(curr_user_id),
        contributors: list_contributors,
        attributors: list_attributors,
        priorities: list_priorities,
        is_contributor: Monitoring.is_contributor?(curr_user_id),
        task_changeset: task_changeset,
        modif_changeset: modif_changeset,
        show_notif: false,

        contributors: Login.list_attributor_and_contributor_users,

        # Par défault, on n'affiche pas show_plus_modal
        show_modif_menu: false,
        show_comments_menu: false,
        show_plus_modal: false,
        delete_task_modal: false,
        arch_id: nil,
        card_with_comments: nil,
        card: nil,
        showing_my_attributes: false,
        showing_my_tasks: true,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
        active_clients: Services.list_active_clients()
      )


    {:ok, socket, layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}}
  end

  def handle_event("tasks_filtered_by_customer", params, socket) do
    IO.inspect(params)

    active_client_id = params["customer_select"]

    tasks =
      case active_client_id do
        "9000" -> Monitoring.list_all_tasks_with_card()
        "-1" -> Monitoring.list_all_tasks_with_card()
        _ ->
          Monitoring.list_all_tasks_with_card_by_active_client_id(active_client_id)
      end

    {:noreply, socket |> assign(tasks: tasks)}
  end

  def handle_event("delete_card", %{"id" => id}, socket) do
    task = Monitoring.get_task_with_card!(id)
    card = Kanban.get_card!(task.card.id)

    Monitoring.remove_card(card.task_id)

    curr_user_id = socket.assigns.curr_user_id
    content = "Tâche #{task.title} supprimé par #{Login.get_user!(curr_user_id).username}."
    Services.send_notifs_to_admins_and_attributors(curr_user_id, content, 3)

    Monitoring.broadcast_deleted_task({:ok, :deleted})

    {:noreply,
      socket
      |> clear_flash()
      |> assign(delete_task_modal: false)
      |> put_flash(:info, "Tâche #{task.title} supprimé.")
      |> push_event("AnimateAlert", %{})
    }
  end

  def handle_event("tasks_filtered_by_contributors", %{"_target" => ["contributor_select"], "contributor_select" => contributor_id}, socket) do
    list_tasks_by_contributor_id =
      case contributor_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card

        "-1" ->
          Monitoring.list_tasks_without_contributor

        _ ->
          Monitoring.list_tasks_by_contributor_id(contributor_id)
      end

    {:noreply, socket |> assign(tasks: list_tasks_by_contributor_id)}
  end

  # Filtrer la liste des contributeurs par contributor_id
  def handle_event("tasks_filtered_by_status", %{"_target" => ["status_id"], "status_id" => status_id}, socket) do
    list_tasks_by_contributor_id = Monitoring.list_tasks_by_status_id(status_id)

    {:noreply, socket |> assign(tasks: list_tasks_by_contributor_id)}
  end

  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id

    switch =
      if socket.assigns.show_notif do
        ids =
          socket.assigns.notifs
          |> Enum.filter(fn x -> !x.seen end)
          |> Enum.map(fn x -> x.id end)

        Services.put_seen_some_notifs(ids)
        false
      else
        true
      end

    {:noreply,
     socket
     |> assign(
       show_notif: switch,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length)
     )}
  end

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length

    {:noreply,
     socket
     |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length + 4))
     |> push_event("SpinTest", %{})}
  end

  def handle_info({Monitoring, [_, _], _}, socket) do
    socket =
      socket
      |> assign(
        tasks: Monitoring.list_all_tasks_with_card()
      )

    {:noreply, socket}
  end


  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length

    {:noreply,
     socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def render(assigns) do
    PmLoginWeb.ProjectView.render("all_tasks.html", assigns)
  end
end
