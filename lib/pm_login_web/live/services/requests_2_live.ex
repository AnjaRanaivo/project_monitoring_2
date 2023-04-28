defmodule PmLoginWeb.Services.Requests2Live do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLoginWeb.LiveComponent.ModalLive
  alias PmLoginWeb.LiveComponent.DetailModalRequestLive
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Task
  alias PmLogin.Monitoring.Project
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLoginWeb.LiveComponent.ClientModalRequestLive
  alias PmLogin.Kanban

  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Services.subscribe()
    Services.subscribe_to_request_topic()

    clients_requests_not_seen = Monitoring.list_clients_requests_not_seen()
    clients_requests_seen = Monitoring.list_clients_requests_seen()
    clients_requests_ongoing = Monitoring.list_clients_requests_ongoing()
    clients_requests_done = Monitoring.list_clients_requests_done()
    clients_requests_finished = Monitoring.list_clients_requests_finished()
    task_changeset = Monitoring.change_task(%Task{})

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    projects = Monitoring.list_projects()
    list_projects = Enum.map(projects, fn %Project{} = p -> {p.title, p.id} end)

    projects_active_client = Monitoring.list_projects()
    list_projects_active_client = Enum.map(projects_active_client, fn %Project{} = p -> {p.title, p.id} end)
    {:ok,
       socket
       |> assign(search_text: nil)
       |> assign(requests: Services.list_requests, show_detail_request_modal: false, client_request: nil,
       show_modal: false, service_id: nil,curr_user_id: curr_user_id,show_notif: false,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
       is_contributor: Monitoring.is_contributor?(curr_user_id),
       clients_requests_not_seen: clients_requests_not_seen,
       clients_requests_seen: clients_requests_seen,
       clients_requests_ongoing: clients_requests_ongoing,
       clients_requests_done: clients_requests_done,
       clients_requests_finished: clients_requests_not_seen,
       clients_requests_finished: clients_requests_finished,
       contributors: list_contributors,
       attributors: list_attributors,
       list_projects: list_projects,
       list_projects_active_client: list_projects_active_client,
       task_changeset: task_changeset,
       show_client_request_modal: false,
       client_request: nil),
       layout: {PmLoginWeb.LayoutView, "board_layout_live.html"}
       }
  end

  def handle_info({ClientModalRequestLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_client_request_modal: false)}
  end

  def handle_event("show_client_request_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)
    request = Services.get_request_with_user_id!(id)
    #list_projects_active_client ovaina an'ny request.active_client_id avec fonction à créer
    projects_active_client = Monitoring.list_projects_by_request(request.project_id)
    #projects_active_client = Monitoring.list_projects()
    list_projects_active_client = Enum.map(projects_active_client, fn %Project{} = p -> {p.title, p.id} end)

    {:noreply, socket |> assign(show_client_request_modal: true, client_request: client_request,list_projects_active_client: list_projects_active_client)}
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
        Monitoring.update_task(task, %{"clients_request_id" => params["client_request_id"]})
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
          # "task_id" => task.id,
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

  #==============================#
  # Showing Survey Request Event #
  #==============================#
  def handle_event("show_survey_request", _params, socket) do
    {:noreply, socket |> redirect(to: Routes.clients_request_path(socket, :survey))}
  end

  def handle_event("modal_close", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("request-search", params, socket) do
    search = params["request_search"]

    requests = Services.search_my_request!(search)

    socket =
      socket
      |> assign(requests: requests)
      |> assign(search_text: search)

    {:noreply, socket}
  end

  def handle_event("request-search-2", params, socket) do
    search = params["request_search"]

    clients_requests_not_seen = Monitoring.search_all_requests_not_seen(search)
    clients_requests_seen = Monitoring.search_all_requests_seen(search)
    clients_requests_ongoing = Monitoring.search_all_requests_ongoing(search)
    clients_requests_done = Monitoring.search_all_requests_done(search)
    clients_requests_finished = Monitoring.search_all_requests_finished(search)

    socket =
      socket
      |> assign(clients_requests_not_seen: clients_requests_not_seen)
      |> assign(clients_requests_seen: clients_requests_seen)
      |> assign(clients_requests_ongoing: clients_requests_ongoing)
      |> assign(clients_requests_done: clients_requests_done)
      |> assign(clients_requests_finished: clients_requests_finished)
      |> assign(search_text: search)

    {:noreply, socket}
  end

  def handle_event("request-status", params, socket) do
    status = params["status_id"]

    requests = Services.list_my_requests_by_status(status)

    socket =
      socket
      |> assign(requests: requests)

    {:noreply, socket}
  end

  def handle_event("switch-seen", params, socket) do

    bool = case params["value"] do
    "on" -> true
      _ -> false
    end

    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"seen" => bool})

    text_vu = case bool do
      true -> "vue"
      _ -> "non vue"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} a été #{text_vu}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("show_detail_request_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)

    {:noreply, socket |> assign(show_detail_request_modal: true, client_request: client_request)}
  end

  def handle_info({DetailModalRequestLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_detail_request_modal: false)}
  end

  def handle_event("switch-ongoing", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"ongoing" => bool})

    text_encours = case bool do
      true -> "est en cours"
      _ -> "n\'est pas en cours"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} #{text_encours}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("switch-done", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"done" => bool})

    text_accomplie = case bool do
      true -> "accomplie"
      _ -> "non accomplie"
    end
    curr_user_id = socket.assigns.curr_user_id

    notif_text = "Requête #{request.title} #{text_accomplie}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)
    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_info({"request_topic", [:request, :updated], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
  end

  def handle_info({"request_topic", [:request, :sent], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
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

  def handle_info({Services, [_, :deleted], _}, socket) do
    editors = Services.list_all_editors
    {:noreply, socket |> assign(editors: editors)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def render(assigns) do
   PmLoginWeb.ClientsRequestView.render("requests_2.html", assigns)
  end

  #del modal component

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-del"}},
      socket
    ) do
  {:noreply, assign(socket, show_modal: false)}
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "del", param: service_id}},
      socket
    ) do
      editor = Services.get_editor!(service_id)
      Services.delete_editor(editor)
      # PmLoginWeb.UserController.archive(socket, user.id)
  {:noreply,
    socket
    |> put_flash(:info, "L'éditeur' #{editor.title} a bien été supprimé!")
    |> push_event("AnimateAlert", %{})
    |> assign(show_modal: false)
      }
  end

  def handle_event("go-del", %{"id" => id}, socket) do
    # Phoenix.LiveView.get_connect_info(socket)
    # put_session(socket, del_id: id)
    {:noreply, assign(socket, show_modal: true, service_id: id)}
  end

end
