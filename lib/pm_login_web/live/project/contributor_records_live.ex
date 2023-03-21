defmodule PmLoginWeb.Project.ContributorRecordsLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.{Project, Task}
  alias PmLogin.Login
  alias PmLogin.Kanban
  alias PmLoginWeb.LiveComponent.TaskModalFromRecordLive

  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    tasks = Monitoring.list_tasks_by_contributor(curr_user_id)
    # tasks_default_filtered = tasks |> Enum.filter(fn task ->  task.status_id != 5 end)

    task_changeset = Monitoring.change_task(%Task{}, %{})

    my_projects = Monitoring.list_projects_by_contributor(curr_user_id)
    list_projects = Enum.map(my_projects, fn %Project{} = p -> {p.title, p.id} end)

    my_actions = Monitoring.list_todays_task_records_by_user(curr_user_id)

    {:ok,
       socket
       |> assign(task_changeset: task_changeset,
                  showing_tasks: true,
                  showing_activities: false,
                  task_display_status: 0,
                  curr_user_id: curr_user_id,
                  list_projects: list_projects,
                  user: Login.get_user_with_function_and_current_record!(curr_user_id),
                  my_tasks: tasks,
                  my_actions: my_actions,
                  show_notif: false,
                  notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
          show_task_modal: false, unachieved: Monitoring.list_my_near_unachieved_tasks(curr_user_id), past_unachieved: Monitoring.list_my_past_unachieved_tasks(curr_user_id)),
       layout: {PmLoginWeb.LayoutView, "contributor_board_live.html"}
       }
  end

  def handle_event("switch_page", %{"task_view" => view}, socket) do

    show_tasks = cond do
      view == "task" ->
        true
      true ->
        false
    end

    show_activities = cond do
      view == "activity" ->
        true
      true ->
        false
    end

    {:noreply, socket |> assign(showing_tasks: show_tasks, showing_activities: show_activities)}
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


  def handle_info({Monitoring, [_, :updated], _}, socket) do
    put_user = Login.get_user_with_function_and_current_record!(socket.assigns.curr_user_id)
    tasks = Monitoring.list_tasks_by_contributor(socket.assigns.curr_user_id)
    my_actions = Monitoring.list_todays_task_records_by_user(socket.assigns.curr_user_id)
    {:noreply, socket |> assign(user: put_user, my_tasks: tasks, my_actions: my_actions)}
  end

  def handle_info({Kanban, [_, _], _}, socket) do
    put_user = Login.get_user_with_function_and_current_record!(socket.assigns.curr_user_id)
    tasks = Monitoring.list_tasks_by_contributor(socket.assigns.curr_user_id)
    {:noreply, socket |> assign(user: put_user, my_tasks: tasks)}
  end


  def handle_info({PmLogin.Monitoring, _event, _content}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    {:noreply, socket |> assign(unachieved: Monitoring.list_my_near_unachieved_tasks(curr_user_id), past_unachieved: Monitoring.list_my_past_unachieved_tasks(curr_user_id))}
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

  def handle_info({TaskModalFromRecordLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_task_modal: false)}
  end

  def handle_event("show_task_modal", _params, socket) do
    IO.puts("task modal")
    {:noreply, socket |> assign(show_task_modal: true)}
  end

  def handle_event("status-selected", %{"status_select" => status}, socket) do
    int_status = String.to_integer(status)

    # curr_user_id = socket.assigns.curr_user_id
    # tasks = Monitoring.list_tasks_by_contributor(curr_user_id)

    # tasks_filtered = cond do
    #   int_status == 0 ->
    #     tasks |> Enum.filter(fn task ->  task.status_id != 5 end)
    #   int_status == 1 ->
    #     tasks |> Enum.filter(fn task ->  task.status_id == 5 end)
    #   true ->
    #       tasks
    # end

    {:noreply, socket |> assign(task_display_status: int_status)}
  end

  def handle_event("stop-record", %{"record_id" => record_id}, socket) do
    # IO.puts "SHTOPPP"
    # IO.inspect record_id

    user = Login.get_user_with_function_and_current_record!(socket.assigns.curr_user_id)
    record = Monitoring.get_record!(String.to_integer(record_id))


    nv_now = NaiveDateTime.local_now()
    recorded_duration = NaiveDateTime.diff(nv_now, record.start, :minute)
    current_task = Monitoring.get_task!(record.task_id)
    current_duration = current_task.performed_duration
    new_duration = recorded_duration + current_duration
    Monitoring.update_task(current_task, %{"performed_duration" => new_duration})


    Monitoring.end_record(record, %{"end" => nv_now, "duration" => recorded_duration})
    {:ok, updated_user} = Login.clean_record_from_user(user)

    put_user = Login.get_user_with_function_and_current_record!(socket.assigns.curr_user_id)

    my_actions = Monitoring.list_todays_task_records_by_user(socket.assigns.curr_user_id)

    {:noreply, socket |> assign(user: put_user, my_tasks: Monitoring.list_tasks_by_contributor(socket.assigns.curr_user_id), my_actions: my_actions)}
  end

  def handle_event("start-meeting", params, socket) do
    IO.puts "MEETING"
    {:noreply, socket}
  end

  def handle_event("start-record", %{"task_id" => task_id}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    # put_new_current_record_to_user

    task = Monitoring.get_task_with_card!(task_id)
    Monitoring.put_task_to_ongoing(task, curr_user_id)

    if not is_nil(socket.assigns.user.current_record) do
      nv_now = NaiveDateTime.local_now()
      Monitoring.end_record(socket.assigns.user.current_record  , %{"end" => nv_now, "duration" => NaiveDateTime.diff(nv_now, socket.assigns.user.current_record.start, :minute)})

      ended_record = Monitoring.get_record!(socket.assigns.user.current_record.id)
      recorded_duration = ended_record.duration
      current_task = Monitoring.get_task!(ended_record.task_id)
      current_duration = current_task.performed_duration
      new_duration = recorded_duration + current_duration
      Monitoring.update_task(current_task, %{"performed_duration" => new_duration})

      Login.clean_record_from_user(socket.assigns.user)
    end

    {:ok, record} = Monitoring.create_task_record(%{"task_id" => String.to_integer(task_id), "user_id" => curr_user_id})
    current_user = Login.get_user!(curr_user_id)
    Login.put_new_current_record_to_user(current_user, %{"current_record_id" => record.id})

    user = Login.get_user_with_function_and_current_record!(curr_user_id)

    my_tasks = socket.assigns.my_tasks
    IO.puts "LENGTH"
    IO.inspect(length(my_tasks))

    my_actions = Monitoring.list_todays_task_records_by_user(socket.assigns.curr_user_id)
    {:noreply, socket |> assign(user: user, my_tasks: socket.assigns.my_tasks, my_actions: my_actions)}
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

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def handle_event("modal_close", %{"key" => key}, socket) do

    show_task_modal = socket.assigns.show_task_modal

    s_task_modal =
      if key == "Escape" and show_task_modal == true, do: false, else: show_task_modal

    {:noreply,
      socket
      |> assign(

        show_task_modal: s_task_modal
        )
    }
  end

  def handle_event("modal_close", %{}, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
   PmLoginWeb.ProjectView.render("contributor_records.html", assigns)
  end

end
