defmodule PmLoginWeb.Project.AllTasksLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Login
  alias PmLogin.Login.{User}
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.{Task, Priority}
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Kanban

# A ajouter dans params
  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    projects = Monitoring.list_projects()

    statuses = Monitoring.list_statuses()

    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})

    priorities = Monitoring.list_priorities()
    list_priorities = Enum.map(priorities, fn %Priority{} = p -> {p.title, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)


    # Init filter parameters
    project_filter = {"Projet", "9000"}
    status_filter = {"Statut", "9000"}
    priority_filter = {"Priorité", "9000"}
    attributor_filter = {"Attributeur", "9000"}
    contributor_filter = {"Contributeur", "9000"}
    customer_filter = {"Client", "9000"}

    customers = Services.list_active_clients()
    list_customers = Enum.map(customers, fn %ActiveClient{} = p -> {p.user.username, p.user.id} end)

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        curr_user_id: curr_user_id,
        tasks: Monitoring.list_all_tasks_with_card(),
        projects: projects,
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
        active_clients: list_customers
      )


    {:ok, socket, layout: {PmLoginWeb.LayoutView, "board_layout_live.html"}}
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

  def init_filter(socket) do
    project_filter =
      case is_nil(socket.assigns.project_filter) do
        true -> {"Projet", "9000"}
        _ -> socket.assigns.project_filter
      end
    status_filter =
      case is_nil(socket.assigns.status_filter) do
        true -> {"Statut", "9000"}
        _ -> socket.assigns.status_filter
      end
    priority_filter =
      case is_nil(socket.assigns.priority_filter) do
        true -> {"Priorité", "9000"}
        _ -> socket.assigns.priority_filter
      end
    attributor_filter =
      case is_nil(socket.assigns.attributor_filter) do
        true -> {"Attributeur", "9000"}
        _ -> socket.assigns.attributor_filter
      end
    contributor_filter =
      case is_nil(socket.assigns.contributor_filter) do
        true -> {"Contributeur", "9000"}
        _ -> socket.assigns.contributor_filter
      end
    customer_filter =
      case is_nil(socket.assigns.customer_filter) do
        true -> {"Client", "9000"}
        _ -> socket.assigns.customer_filter
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter
      )
    {:noreply, socket }
  end

  def init_tasks(socket) do
    tasks =
      case Enum.count(socket.assigns.tasks) do
        0 -> Monitoring.list_all_tasks_with_card
        _ -> socket.assigns.tasks
      end
    {:noreply,
      socket
      |> assign(tasks: tasks)
    }
  end

  # Project filter
  def handle_event("tasks_filtered_by_project", %{"_target" => ["project_id"], "project_id" => project_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_project =
      case project_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card
        _ ->
          Monitoring.list_tasks_by_project(project_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(tasks, MapSet.new),
                                      Enum.into(list_tasks_by_project, MapSet.new))
                                      |> MapSet.to_list

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_project
                        end

    project = Monitoring.get_project!(project_id)
    project_filter = {project.title, project.id}

    status_filter =
      if length(list_tasks) > 0 do
        socket.assigns.status_filter
      else
        {"Statut", "9000"}
      end
    priority_filter =
      if length(list_tasks) > 0 do
        socket.assigns.priority_filter
      else
        {"Priorité", "9000"}
      end
    attributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.attributor_filter
      else
        {"Attributeur", "9000"}
      end
    contributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.contributor_filter
      else
        {"Contributeur", "9000"}
      end
    customer_filter =
      if length(list_tasks) > 0 do
        socket.assigns.customer_filter
      else
        {"Client", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
  end

  # Status filter
  def handle_event("tasks_filtered_by_status", %{"_target" => ["status_id"], "status_id" => status_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_status =
      case status_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card
        _ ->
          Monitoring.list_tasks_by_status_id(status_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(list_tasks_by_status, MapSet.new),
                                      Enum.into(tasks, MapSet.new))
                                      |> MapSet.to_list

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_status
                        end

    status = Monitoring.get_status!(status_id)
    status_filter = {status.title, status.id}

    project_filter =
      if length(list_tasks) > 0 do
        socket.assigns.project_filter
      else
        {"Projet", "9000"}
      end
    priority_filter =
      if length(list_tasks) > 0 do
        socket.assigns.priority_filter
      else
        {"Priorité", "9000"}
      end
    attributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.attributor_filter
      else
        {"Attributeur", "9000"}
      end
    contributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.contributor_filter
      else
        {"Contributeur", "9000"}
      end
    customer_filter =
      if length(list_tasks) > 0 do
        socket.assigns.customer_filter
      else
        {"Client", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
  end

  # Priority filter
  def handle_event("tasks_filtered_by_priority", %{"_target" => ["priority_id"], "priority_id" => priority_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_priority =
      case priority_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card
        _ ->
          Monitoring.list_tasks_by_priority(priority_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(list_tasks_by_priority, MapSet.new),
                                      Enum.into(tasks, MapSet.new))
                                      |> MapSet.to_list

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_priority
                        end

    priority = Monitoring.get_priority!(priority_id)
    priority_filter = {priority.title, priority.id}

    project_filter =
      if length(list_tasks) > 0 do
        socket.assigns.project_filter
      else
        {"Projet", "9000"}
      end
    status_filter =
      if length(list_tasks) > 0 do
        socket.assigns.status_filter
      else
        {"Statut", "9000"}
      end
    attributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.attributor_filter
      else
        {"Attributeur", "9000"}
      end
    contributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.contributor_filter
      else
        {"Contributeur", "9000"}
      end
    customer_filter =
      if length(list_tasks) > 0 do
        socket.assigns.customer_filter
      else
        {"Client", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
  end

  # Attributor filter
  def handle_event("tasks_filtered_by_attributor", %{"_target" => ["attributor_id"], "attributor_id" => attributor_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_attributor =
      case attributor_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card

        "-1" ->
          Monitoring.list_tasks_without_attributor

        _ ->
          Monitoring.list_tasks_by_attributor(attributor_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(list_tasks_by_attributor, MapSet.new),
                                    Enum.into(tasks, MapSet.new))
                                    |> MapSet.to_list

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_attributor
                        end

    attributor = Login.get_user!(attributor_id)
    attributor_filter = {attributor.username, attributor.id}

    project_filter =
      if length(list_tasks) > 0 do
        socket.assigns.project_filter
      else
        {"Projet", "9000"}
      end
    status_filter =
      if length(list_tasks) > 0 do
        socket.assigns.status_filter
      else
        {"Statut", "9000"}
      end
    priority_filter =
      if length(list_tasks) > 0 do
        socket.assigns.priority_filter
      else
        {"Priorité", "9000"}
      end
    contributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.contributor_filter
      else
        {"Contributeur", "9000"}
      end
    customer_filter =
      if length(list_tasks) > 0 do
        socket.assigns.customer_filter
      else
        {"Client", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
  end

  # Contributor filter
  def handle_event("tasks_filtered_by_contributor", %{"_target" => ["contributor_id"], "contributor_id" => contributor_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_contributor =
      case contributor_id do
        "9000" ->
          Monitoring.list_all_tasks_with_card

        "-1" ->
          Monitoring.list_tasks_without_contributor

        _ ->
          Monitoring.list_tasks_by_contributor_id(contributor_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(list_tasks_by_contributor, MapSet.new),
                                      Enum.into(tasks, MapSet.new))
                                      |> MapSet.to_list

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_contributor
                        end

    contributor = Login.get_user!(contributor_id)
    contributor_filter = {contributor.username, contributor.id}

    project_filter =
      if length(list_tasks) > 0 do
        socket.assigns.project_filter
      else
        {"Projet", "9000"}
      end
    status_filter =
      if length(list_tasks) > 0 do
        socket.assigns.status_filter
      else
        {"Statut", "9000"}
      end
    priority_filter =
      if length(list_tasks) > 0 do
        socket.assigns.priority_filter
      else
        {"Priorité", "9000"}
      end
    attributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.attributor_filter
      else
        {"Attributeur", "9000"}
      end
    customer_filter =
      if length(list_tasks) > 0 do
        socket.assigns.customer_filter
      else
        {"Client", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
  end

  # Customer Filter
  def handle_event("tasks_filtered_by_customer", %{"_target" => ["customer_id"], "customer_id" => customer_id}, socket) do
    # Init parameters
    init_filter(socket)

    # Init tasks already on filter
    init_tasks(socket)
    tasks = socket.assigns.tasks

    # New filter request
    list_tasks_by_customer =
      case customer_id do
        "9000" -> Monitoring.list_all_tasks_with_card()
        _ ->
          Monitoring.list_all_tasks_with_card_by_active_client_user_id(customer_id)
      end

    # Final tasks list
    list_tasks = MapSet.intersection(Enum.into(list_tasks_by_customer, MapSet.new),
                                      Enum.into(tasks, MapSet.new))
                                      |> MapSet.to_list

    # result_list_tasks = if length(list_tasks) > 0 do
    #                       list_tasks
    #                     else
    #                       Monitoring.list_tasks_by_project_status_priority_attributor_contributor_customer(
    #                                                                                                         elem(socket.assigns.project_filter, 1),
    #                                                                                                         elem(socket.assigns.status_filter, 1),
    #                                                                                                         elem(socket.assigns.priority_filter, 1),
    #                                                                                                         elem(socket.assigns.attributor_filter, 1),
    #                                                                                                         elem(socket.assigns.contributor_filter, 1),
    #                                                                                                         customer_id
    #                                                                                                       )
    #                     end

    result_list_tasks = if length(list_tasks) > 0 do
                          list_tasks
                        else
                          list_tasks_by_customer
                        end

    IO.puts("--------------------------------------------------------------------")
    IO.inspect(Enum.into(list_tasks_by_customer, MapSet.new))

    customer = Login.get_user!(customer_id)
    customer_filter = {customer.username, customer.id}

    project_filter =
      if length(list_tasks) > 0 do
        socket.assigns.project_filter
      else
        {"Projet", "9000"}
      end
    status_filter =
      if length(list_tasks) > 0 do
        socket.assigns.status_filter
      else
        {"Statut", "9000"}
      end
    priority_filter =
      if length(list_tasks) > 0 do
        socket.assigns.priority_filter
      else
        {"Priorité", "9000"}
      end
    attributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.attributor_filter
      else
        {"Attributeur", "9000"}
      end
    contributor_filter =
      if length(list_tasks) > 0 do
        socket.assigns.contributor_filter
      else
        {"Contributeur", "9000"}
      end

    socket =
      socket
      |> assign(
        project_filter: project_filter,
        status_filter: status_filter,
        priority_filter: priority_filter,
        attributor_filter: attributor_filter,
        contributor_filter: contributor_filter,
        customer_filter: customer_filter,
        tasks: result_list_tasks
      )

    {:noreply, socket }
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
