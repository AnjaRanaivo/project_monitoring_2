defmodule PmLoginWeb.ProjectController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Project
  alias PmLogin.Services.ActiveClient
  alias Phoenix.LiveView
  alias PmLogin.Login
  alias PmLogin.Email
  alias PmLogin.Services

  def board(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_contributor?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.BoardLive,
            session: %{"curr_user_id" => get_session(conn, :curr_user_id), "pro_id" => id},
            router: PmLoginWeb.Router
          )

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def recaps(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.RecapsLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def index(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.IndexLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

          # BY THE OLD WAY
          # projects = Monitoring.list_projects()
          # render(conn, "index.html", projects: projects, layout: {PmLoginWeb.LayoutView, "board_layout_live.html"})

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def requests_center(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.RequestsCenterLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

          # BY THE OLD WAY
          # projects = Monitoring.list_projects()
          # render(conn, "index.html", projects: projects, layout: {PmLoginWeb.LayoutView, "board_layout_live.html"})

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def new(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          changeset = Monitoring.change_project(%Project{})
          ac_list = Services.list_active_clients
          ac_ids = Enum.map(ac_list, fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end )
          # render(conn, "new.html", changeset: changeset, ac_ids: ac_ids, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.NewLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset, "ac_ids" => ac_ids}, router: PmLoginWeb.Router)
        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

end

  def create(conn, %{"project" => project_params}) do
    IO.inspect(project_params)

    IO.inspect(conn)
    case Monitoring.create_project(project_params) do
      {:ok, project} ->
        Services.send_notifs_to_admins_and_attributors(Login.get_curr_user_id(conn), "Un projet du nom de #{project.title} a été crée par #{Login.get_curr_user(conn).username}", 5)
        conn
        |> put_flash(:info, "Projet #{Monitoring.get_project!(project.id).title} crée avec succès")
        |> redirect(to: Routes.project_path(conn, :board, project))


      {:error, %Ecto.Changeset{} = changeset} ->
        ac_list = Services.list_active_clients
        ac_ids = Enum.map(ac_list, fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end )
        # render(conn, "new.html", changeset: changeset, ac_ids: ac_ids)
        LiveView.Controller.live_render(conn, PmLoginWeb.Project.NewLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset, "ac_ids" => ac_ids}, router: PmLoginWeb.Router)
    end
  end

  def show(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          project = Monitoring.get_project!(id)
          # render(conn, "show.html", project: project, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.ShowLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "project" => project}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def edit(conn, %{"id" => id}) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          project = Monitoring.get_project!(id)
          changeset = Monitoring.change_project(project)

          ac_list = Services.list_active_clients
          ac_ids = Enum.map(ac_list, fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end )

          status = Monitoring.list_statuses_title()

          # render(conn, "edit.html", project: project, changeset: changeset, ac_ids: ac_ids, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.EditLive,
          session: %{"curr_user_id" => get_session(conn, :curr_user_id),
          "project" => project, "changeset" => changeset,
          "ac_ids" => ac_ids, "status" => status}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Monitoring.get_project!(id)

    case Monitoring.update_project(project, project_params) do
      {:ok, project} ->

        email =
          if project.status_id == 5 do
            client_request_id = Services.get_client_request_id_by_project!(project.id)

            if not is_nil(client_request_id) do
              request = Services.get_request_with_user_id!(client_request_id)

              Login.get_user!(request.active_client.user_id).email
            end
          else
            nil
          end

        id =
          if project.status_id == 5 do
            client_request_id = Services.get_client_request_id_by_project!(project.id)

            if not is_nil(client_request_id) do
              request = Services.get_request_with_user_id!(client_request_id)

              request.id
            end
          else
            nil
          end

        if project.status_id == 5 do
          client_request_id = Services.get_client_request_id_by_project!(project.id)

          if not is_nil(client_request_id) do
            request = Services.get_request_with_user_id!(client_request_id)

            params = %{
              "date_done" => NaiveDateTime.local_now(),
              "done" => true
            }

            Services.update_clients_request(request, params)
          end
        else
          client_request_id = Services.get_client_request_id_by_project!(project.id)

          if not is_nil(client_request_id) do
            request = Services.get_request_with_user_id!(client_request_id)

            params = %{
              "date_done" => nil,
              "done" => nil
            }

            Services.update_clients_request(request, params)
          end
        end

        # Envoyer l'email immédiatement
        if not is_nil(email) and not is_nil(id), do: Email.send_state_of_client_request("nambinintsoa.dev@gmail.com", id)

        Services.send_notifs_to_admins_and_attributors(Login.get_curr_user_id(conn), "Le projet \"#{project.title}\" a été mise à jour par #{Login.get_curr_user(conn).username}", 7)
        conn
        |> put_flash(:info, "Projet mis à jour.")
        |> redirect(to: Routes.project_path(conn, :show, project))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "edit.html", project: project, changeset: changeset)
        ac_list = Services.list_active_clients
        status = Monitoring.list_statuses_title()
        ac_ids = Enum.map(ac_list, fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end )
        LiveView.Controller.live_render(conn, PmLoginWeb.Project.EditLive,
        session: %{"curr_user_id" => get_session(conn, :curr_user_id),
        "project" => project, "changeset" => changeset, "ac_ids" => ac_ids,
        "status" => status},
         router: PmLoginWeb.Router)

    end
  end

  def delete(conn, %{"id" => id}) do
    project = Monitoring.get_project!(id)
    {:ok, _project} = Monitoring.delete_project(project)

    conn
    |> put_flash(:info, "Projet supprimé.")
    |> redirect(to: Routes.project_path(conn, :index))
  end

  def contributors(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.ContributorsLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def show_contributor(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.ShowContributorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "contributor_id" => id}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def tasks(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.AttributorTasksLive, session: %{
            "tasks" => get_session(conn, :curr_user_id)
            |> Monitoring.list_tasks_by_attributor_project,
            "curr_user_id" => Login.get_curr_user(conn).id
          },
          router: PmLoginWeb.Router
        )
      true ->
        conn
        |> Login.not_attributor_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def attributed_tasks(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.AttributorAttributedTasksLive, session: %{
            "tasks" => get_session(conn, :curr_user_id)
            |> Monitoring.list_attributes_tasks_by_attributor_project,
            "curr_user_id" => Login.get_curr_user(conn).id
          },
          router: PmLoginWeb.Router
        )
      true ->
        conn
        |> Login.not_attributor_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  # Logs: Historiques
  def logs(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) or Login.is_attributor?(conn) ->
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.LogsLive,
            session: %{"curr_user_id" => get_session(conn, :curr_user_id)},
            router: PmLoginWeb.Router
          )

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def all_tasks(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.AllTasksLive,
            session: %{"curr_user_id" => get_session(conn, :curr_user_id)},
            router: PmLoginWeb.Router
          )

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

end
