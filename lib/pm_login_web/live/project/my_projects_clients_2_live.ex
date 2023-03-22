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

  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    # IO.puts "CLIENTS REQUESTS"
    # IO.inspect not_ongoing_requests |> Enum.map(&(&1.title))
    # IO.inspect not_ongoing_requests |> length()
    # IO.inspect not_ongoing_requests |> Enum.at(10)

    projects = Monitoring.list_projects_by_clients_user_id(curr_user_id)

    layout = {PmLoginWeb.LayoutView, "active_client_2_layout_live.html"}

    {:ok,
      socket
      |> assign(
        projects: projects,
        curr_user_id: curr_user_id,
        show_project_modal: false,
        show_notif: false,
        search_text: nil,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
        client_request: nil
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

end
