defmodule PmLoginWeb.Project.MyProjectsClients2Live do
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
  alias PmLogin.Services.ClientsRequest

  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    # IO.puts "CLIENTS REQUESTS"
    # IO.inspect not_ongoing_requests |> Enum.map(&(&1.title))
    # IO.inspect not_ongoing_requests |> length()
    # IO.inspect not_ongoing_requests |> Enum.at(10)

    projects = Monitoring.list_projects_by_clients_user_id(curr_user_id)
    list_projects = Enum.map(projects, fn %Project{} = p -> {p.title, p.id} end)

    layout = {PmLoginWeb.LayoutView, "active_client_2_layout_live.html"}

    {:ok,
      socket
      |> assign(
        changeset: Services.change_clients_request(%ClientsRequest{}),
        display_form: false,
        projects: Monitoring.list_projects(),
        curr_user_id: curr_user_id,
        show_project_modal: false,
        show_notif: false,
        search_text: nil,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
        list_projects: list_projects,
        client_request: nil,
        )
        |> allow_upload(:file,
          accept:
            ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .csv .xml .xls .xlsx .ppt .pptx .doc .docx),
          max_entries: 5
        ),
        layout: layout
    }
  end

  def handle_event("search-project", params, socket) do

    project_title = params["project_search"]

    projects = Monitoring.list_project_by_title_and_user_client!(project_title,socket.assigns.curr_user_id)

    {:noreply, socket |> assign(projects: projects)}
  end

  def handle_event("status-project", params, socket) do
    status_id = params["status_id"]

    if status_id != "0" do
      {:noreply, socket |> assign(projects: Monitoring.list_project_by_status_and_user_client!(status_id,socket.assigns.curr_user_id))}
    else
      {:noreply, socket |> assign(projects: Monitoring.list_projects_by_clients_user_id(socket.assigns.curr_user_id))}
    end

  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end



  def render(assigns) do
    ProjectView.render("active_client_2_index.html", assigns)
  end

  def handle_event("form-on", _params, socket) do
    {:noreply,
      socket
      |> clear_flash()
      |> assign(display_form: true)}
  end

  def handle_event("form-off", _params, socket) do
    {:noreply, socket |> assign(display_form: false)}
  end

  def handle_event("change-request", params, socket) do
    # IO.inspect(params)
    {:noreply, socket}
  end

  def handle_event("send-request", %{"clients_request" => params}, socket) do
    # Added uuid to the current params
    params = Map.put_new(params, "uuid", Uuid.generate)

    {entries, []} = uploaded_entries(socket, :file)
    # IO.inspect(entries)

    # urls = for entry <- entries do
    #   Routes.static_path(socket, "/uploads/#{entry.uuid}#{Path.extname(entry.client_name)}")
    # end

    # IO.inspect urls

    # consume_uploaded_entries(socket, :file, fn meta, entry ->
    #   dest = Path.join("priv/static/uploads", "#{entry.uuid}#{Path.extname(entry.client_name)}")
    #   File.cp!(meta.path, dest)
    #  end)
    # IO.inspect socket.assigns.uploads[:file].entries

    case Services.create_clients_request(params) do
      {:ok, result} ->
        consume_uploaded_entries(socket, :file, fn meta, entry ->
          ext = Path.extname(entry.client_name)
          file_name = Path.basename(entry.client_name, ext)
          dest = Path.join("priv/static/uploads", "#{file_name}#{entry.uuid}#{ext}")
          File.cp!(meta.path, dest)
        end)

        {entries, []} = uploaded_entries(socket, :file)

        urls =
          for entry <- entries do
            ext = Path.extname(entry.client_name)
            file_name = Path.basename(entry.client_name, ext)
            Routes.static_path(socket, "/uploads/#{file_name}#{entry.uuid}#{ext}")
          end

        Services.update_request_files(result, %{"file_urls" => urls})

        {:ok, result} |> Services.broadcast_request()
        # sending notifs to admins
        curr_user_id = socket.assigns.curr_user_id
        the_client = Services.get_active_client_from_userid!(curr_user_id)

        Services.send_notifs_to_admins(
          curr_user_id,
          "Le client #{the_client.user.username} de la société #{the_client.company.name} a envoyé une requête intitulée \"#{result.title}\".",
          5
        )

        Monitoring.broadcast_clients_requests({:ok, :clients_requests})

        {:noreply,
         socket
         |> assign(
           display_form: false,
           changeset: Services.change_clients_request(%ClientsRequest{})
         )
         |> put_flash(:info, "Requête envoyée")
         |> push_event("AnimateAlert", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

end
