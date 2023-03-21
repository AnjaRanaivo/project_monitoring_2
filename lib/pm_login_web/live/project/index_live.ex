defmodule PmLoginWeb.Project.IndexLive do
  use Phoenix.LiveView
  alias PmLoginWeb.ProjectView
  alias PmLogin.Monitoring
  alias PmLogin.Services
  alias PmLogin.Login
  alias PmLogin.Kanban
  alias PmLogin.Login.User
  alias PmLogin.Monitoring.{Task, Project}
  alias PmLoginWeb.LiveComponent.{ClientModalRequestLive, DetailModalRequestLive, ProjectModalLive}
  alias PmLogin.Email

  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    list_clients_requests = Services.list_clients_requests_with_client_name
    not_ongoing_requests = Services.list_not_ongoing_clients_requests
    next_shown = cond do
      length(not_ongoing_requests) <= 1 -> false
      true -> true
    end

    # IO.puts "CLIENTS REQUESTS"
    # IO.inspect not_ongoing_requests |> Enum.map(&(&1.title))
    # IO.inspect not_ongoing_requests |> length()
    # IO.inspect not_ongoing_requests |> Enum.at(10)

    task_changeset = Monitoring.change_task(%Task{})

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    projects = Monitoring.list_projects()
    list_projects = Enum.map(projects, fn %Project{} = p -> {p.title, p.id} end)

    layout =
      case Login.get_user!(curr_user_id).right_id do
        1 -> {PmLoginWeb.LayoutView, "board_layout_live.html"}
        2 -> {PmLoginWeb.LayoutView, "attributor_board_live.html"}
        _ -> {}
      end

    {:ok,
      socket
      |> assign(
        is_attributor: Monitoring.is_attributor?(curr_user_id),
        is_admin: Monitoring.is_admin?(curr_user_id),
        is_contributor: Monitoring.is_contributor?(curr_user_id),
        task_changeset: task_changeset,
        list_clients_requests: list_clients_requests,
        projects: Monitoring.list_projects(),
        curr_user_id: curr_user_id,
        contributors: list_contributors,
        attributors: list_attributors,
        show_client_request_modal: false,
        show_detail_request_modal: false,
        show_project_modal: false,
        show_notif: false,
        list_projects: list_projects,
        client_request: nil,
        not_ongoing_requests: not_ongoing_requests,
        not_ongoing_index: 0,
        prev_shown: false,
        next_shown: next_shown,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)
        ),
        layout: layout
    }
  end

  def handle_event("inc_ongoing_index", _params, socket) do
    not_ongoing_index = socket.assigns.not_ongoing_index
    current_index_id = not_ongoing_index+1
    size = socket.assigns.not_ongoing_requests |> length()
    max_index = size-1
    is_next_shown = cond do
      current_index_id == max_index -> false
      true -> true
    end
    IO.puts("CURRENT INDEX: #{current_index_id} MAX INDEX: #{max_index}")
    IO.inspect is_next_shown
    {:noreply, socket |> assign(not_ongoing_index: current_index_id, prev_shown: true, next_shown: is_next_shown)}
  end

  def handle_event("dec_ongoing_index", _params, socket) do
    current_index_id = socket.assigns.not_ongoing_index
    is_prev_shown = cond do
      current_index_id == 1 -> false
      true -> true

    end
    IO.inspect current_index_id
    IO.inspect is_prev_shown
    {:noreply, socket |> assign(not_ongoing_index: current_index_id-1, prev_shown: is_prev_shown, next_shown: true)}
  end

  def handle_event("search-project", params, socket) do

    project_title = params["project_search"]

    projects = Monitoring.list_project_by_title!(project_title)

    {:noreply, socket |> assign(projects: projects)}
  end

  def handle_event("status-project", params, socket) do
    status_id = params["status_id"]

    if status_id != "0" do
      {:noreply, socket |> assign(projects: Monitoring.list_project_by_status!(status_id))}
    else
      {:noreply, socket |> assign(projects: Monitoring.list_projects())}
    end

  end

  def handle_event("previous-client-request", %{"date_post" => date_post}, socket) do
    # Convertir la date de publication en NaiveDateTime
    date_post = NaiveDateTime.from_iso8601!(date_post)

    list_clients_requests = Services.list_clients_requests_with_client_name_previous(date_post)

    {:noreply, socket |> assign(list_clients_requests: list_clients_requests)}
  end

  def handle_event("next-client-request", %{"date_post" => date_post}, socket) do
    # Convertir la date de publication en NaiveDateTime
    date_post = NaiveDateTime.from_iso8601!(date_post)

    list_clients_requests = Services.list_clients_requests_with_client_name_next(date_post)

    {:noreply, socket |> assign(list_clients_requests: list_clients_requests)}
  end

  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id
    switch = if socket.assigns.show_notif do
              ids = socket.assigns.notifs
                    |> Enum.filter(fn(x) -> !(x.seen) end)
                    |> Enum.map(fn(x) -> x.id  end)
              Services.put_seen_some_notifs(ids)
                false
              else
                true
             end
    {:noreply, socket |> assign(show_notif: switch, notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length))}
  end

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4)) |> push_event("SpinTest", %{})}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  def handle_event("show_client_request_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)

    request = Services.get_request_with_user_id!(id)
    Services.update_request_bool(request, %{"seen" => true})

    # Mettre à jour la date de vue
    Services.update_clients_request(request, %{"date_seen" => NaiveDateTime.local_now()})

    {:noreply, socket |> assign(show_client_request_modal: true, client_request: client_request)}
  end

  # Afficher les détails du requête client dans la liste des projets
  def handle_event("show_detail_request_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)

    request = Services.get_request_with_user_id!(id)

    Services.update_request_bool(request, %{"seen" => true})

    # Mettre à jour la date de vue
    Services.update_clients_request(request, %{"date_seen" => NaiveDateTime.local_now()})

    user = Login.get_user!(request.active_client.user_id)

    # Envoyer l'email immédiatement
    if not request.seen, do: Process.send_after(self(), :send_email_to_user, 0)

    {:noreply, socket |> assign(show_detail_request_modal: true, client_request: client_request, email: user.email, id: id)}
  end

  def handle_info(:send_email_to_user, socket) do
    email = socket.assigns.email
    id = socket.assigns.id

    # Envoyer un mail indiquant que le requête a été vue par l'administrateur
    Email.send_state_of_client_request(email, id)

    {:noreply, socket}
  end

  def handle_event("show_project_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)

    request = Services.get_request_with_user_id!(id)
    Services.update_request_bool(request, %{"seen" => true})

    user = Login.get_user!(request.active_client.user_id)

    # Envoyer l'email immédiatement
    if not request.seen, do: Process.send_after(self(), :send_email_to_user, 0)

    # Mettre à jour la date de vue
    Services.update_clients_request(request, %{"date_seen" => NaiveDateTime.local_now()})

    {:noreply, socket |> assign(show_project_modal: true, client_request: client_request, email: user.email, id: request.id)}
  end


  def handle_event("create", %{"task" => project_params}, socket) do
    hour        = String.to_integer(project_params["hour"])
    minutes     = String.to_integer(project_params["minutes"])
    estimated_duration  = (hour * 60) + minutes

    project_params =
      project_params
      |> Map.put("estimated_duration", estimated_duration)
      |> Map.put("active_client_id", project_params["client_id"])
      |> Map.put("client_request_id", project_params["client_request_id"])
      |> Map.delete("hour")
      |> Map.delete("minutes")
      |> Map.delete("client_id")
      |> Map.delete("attributor_id")

    case Monitoring.create_project(project_params) do
      {:ok, project} ->
        # Mettre la requête en vue
        request = Services.get_request_with_user_id!(project_params["client_request_id"])
        Services.update_request_bool(request, %{"ongoing" => true})

        # Mettre à jour la date de de mise en cours du requête
        Services.update_clients_request(request, %{"date_ongoing" => NaiveDateTime.local_now()})

        clients_request = Services.get_clients_request!(project_params["client_request_id"])

        clients_request_params = %{
          "project_id" => project.id
        }

        Services.update_clients_request(clients_request, clients_request_params)

        user = Login.get_user!(request.active_client.user_id)

        # Envoyer l'email immédiatement
        if not request.ongoing, do: Process.send_after(self(), :send_email_to_user, 0)

        # Changement en direct
        Monitoring.broadcast_clients_requests({:ok, :clients_requests})

        {:noreply,
          socket
          |> assign(show_project_modal: false, email: user.email, id: request.id)
          |> put_flash(:info, "Le projet #{Monitoring.get_project!(project.id).title} a été créé avec succès")
          # |> push_redirect(to: "/boards/#{Monitoring.get_project!(project.id).id}")
        }

      {:error, _} ->
        {:noreply,
          socket
          |> assign(show_project_modal: false)
          |> put_flash(:error, "Une erreur a été produite lors du création du projet")
        }
    end
  end

  def handle_event("modal_close", %{"key" => key}, socket) do
    show_client_request_modal = socket.assigns.show_client_request_modal
    show_detail_request_modal = socket.assigns.show_detail_request_modal
    show_project_modal        = socket.assigns.show_project_modal

    s_cli_request_modal =
      if key == "Escape" and show_client_request_modal == true, do: false, else: show_client_request_modal

    s_det_request_modal =
      if key == "Escape" and show_detail_request_modal == true, do: false, else: show_detail_request_modal

    s_pro_modal =
      if key == "Escape" and show_project_modal == true, do: false, else: show_project_modal

    {:noreply,
      socket
      |> assign(
        show_client_request_modal: s_cli_request_modal,
        show_detail_request_modal: s_det_request_modal,
        show_project_modal: s_pro_modal
        )
    }
  end

  def handle_event("modal_close", %{}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"task" => params}, socket) do
    # IO.inspect params["estimated_duration"]
    # IO.puts("#{is_integer(params["estimated_duration"])}")



    IO.inspect(params)

    pro_id = params["project_id"]

    project = Monitoring.get_project!(pro_id)
    board = Kanban.get_board!(project.board_id)

    hour        = String.to_integer(params["hour"])
    minutes     = String.to_integer(params["minutes"])

    total_minutes  = (hour * 60) + minutes

    # Ajouter la durée estimée dans le map
    params =
      params
      |> Map.put("estimated_duration", total_minutes)
      |> Map.put("client_request_id", params["client_request_id"])

    new_params =
      if Login.get_user!(params["attributor_id"]).right_id == 3,
        do: Map.put(params, "contributor_id", params["attributor_id"]),
        else: params

    # IO.inspect new_params

    case Monitoring.create_task_with_card(new_params) do
      {:ok, task} ->
        this_board = board

        this_project = board.project
        Monitoring.substract_project_progression_when_creating_primary(this_project)

        [head | _] = this_board.stages
        Kanban.create_card(%{name: task.title, stage_id: head.id, task_id: task.id})
        # SEND NEW TASK NOTIFICATION TO ADMINS AND ATTRIBUTORS
        curr_user_id = socket.assigns.curr_user_id

        Services.send_notifs_to_admins_and_attributors(
          curr_user_id,
          "Tâche nouvellement créee du nom de #{task.title} par #{Login.get_user!(curr_user_id).username} dans le projet #{this_project.title}.",
          5
        )

        # Mettre la requête en vue
        request = Services.get_request_with_user_id!(params["client_request_id"])
        Services.update_request_bool(request, %{"ongoing" => true})

        # Mettre à jour la date de de mise en cours du requête
        Services.update_clients_request(request, %{"date_ongoing" => NaiveDateTime.local_now()})


        # Mettre à jour task_id et project_id à partir de la tâche créée
        clients_request = Services.get_clients_request!(params["client_request_id"])

        clients_request_params = %{
          "task_id" => task.id,
          "project_id" => task.project_id
        }

        Services.update_clients_request(clients_request, clients_request_params)

        user = Login.get_user!(request.active_client.user_id)

        # Envoyer l'email immédiatement
        if not request.ongoing, do: Process.send_after(self(), :send_email_to_user, 0)

        # Changement en direct
        Monitoring.broadcast_clients_requests({:ok, :clients_requests})

        if not is_nil(task.contributor_id) do
          Services.send_notif_to_one(
            curr_user_id,
            task.contributor_id,
            "#{Login.get_user!(task.contributor_id).username} vous a assigné à la tâche #{task.title} dans le projet #{this_project.title}.",
            6
          )

          Services.send_notifs_to_admins(
            curr_user_id,
            "#{Login.get_user!(task.contributor_id).username} vous a assigné à la tâche #{task.title} dans le projet #{this_project.title}.",
            6
          )
        end

        {:noreply,
         socket
         |> put_flash(:info, "La tâche #{Monitoring.get_task!(task.id).title} a bien été créee")
         |> push_event("AnimateAlert", %{})
         |> assign(show_client_request_modal: false, email: user.email, id: request.id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, task_changeset: changeset)}
    end
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def handle_info({"request_topic", [:request, :updated], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_my_requests(socket.assigns.curr_user_id))}
  end

  def handle_info({ClientModalRequestLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_client_request_modal: false)}
  end

  def handle_info({DetailModalRequestLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_detail_request_modal: false)}
  end

  def handle_info({ProjectModalLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_project_modal: false)}
  end

  def handle_info({Monitoring, [:request, :created], _}, socket) do

    projects = Monitoring.list_projects()
    list_projects = Enum.map(projects, fn %Project{} = p -> {p.title, p.id} end)

    {:noreply,
      socket |> assign(list_clients_requests: Services.list_clients_requests_with_client_name,
                       projects: Monitoring.list_projects,
                       list_projects: list_projects)
    }
  end

  def handle_info({Monitoring, [:project, :updated], _}, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ProjectView.render("index.html", assigns)
  end
end
