defmodule PmLoginWeb.ContributorController do
  use PmLoginWeb, :controller

  alias PmLogin.Monitoring
  alias PmLogin.Login
  alias Phoenix.LiveView

  def my_projects(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_contributor?(conn) ->
          # conn
          # |> render("my_projects.html", projects: get_session(conn, :curr_user_id)
          #                                         |> Monitoring.list_projects_by_contributor,
          #                               layout: {PmLoginWeb.LayoutView, "contributor_layout.html"})
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.ContributorProjectsLive,
            session: %{
              "projects" => get_session(conn, :curr_user_id)
              |> Monitoring.list_projects_by_contributor,"curr_user_id" => Login.get_curr_user(conn).id
            },
            router: PmLoginWeb.Router
          )
        true ->
          conn
            |> Login.not_contributor_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def my_records(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_contributor?(conn) ->
          # conn
          # |> render("my_projects.html", projects: get_session(conn, :curr_user_id)
          #                                         |> Monitoring.list_projects_by_contributor,
          #                               layout: {PmLoginWeb.LayoutView, "contributor_layout.html"})
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.ContributorRecordsLive,
            session: %{
              "curr_user_id" => get_session(conn, :curr_user_id)

            },
            router: PmLoginWeb.Router
          )
        true ->
          conn
            |> Login.not_contributor_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def my_tasks(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_contributor?(conn) ->
          LiveView.Controller.live_render(
            conn,
            PmLoginWeb.Project.ContributorTasksLive,
            session: %{
              "tasks" => get_session(conn, :curr_user_id)
              |> Monitoring.list_tasks_by_contributor_project,"curr_user_id" => Login.get_curr_user(conn).id
            },
            router: PmLoginWeb.Router
          )
        true ->
          conn
          |> Login.not_contributor_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

end
