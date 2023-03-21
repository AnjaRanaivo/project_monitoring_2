defmodule PmLoginWeb.ClientsRequestController do
  use PmLoginWeb, :controller
  alias Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Services.ClientsRequest
  alias PmLogin.Login

  def index(conn, _params) do
    clients_requests = Services.list_clients_requests()
    render(conn, "index.html", clients_requests: clients_requests)
  end

  def requests(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
            LiveView.Controller.live_render(conn, PmLoginWeb.Services.RequestsLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def my_requests(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_active_client?(conn) ->
            LiveView.Controller.live_render(conn, PmLoginWeb.Services.MyRequestsLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |>Login.not_active_client_redirection

      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def survey(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
            LiveView.Controller.live_render(conn, PmLoginWeb.Services.SurveyRequestLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  #=========================#
  # Client tasks controller #
  #=========================#
  def client_tasks(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_active_client?(conn) ->
            LiveView.Controller.live_render(conn, PmLoginWeb.Services.ClientTasksLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |>Login.not_active_client_redirection

      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def client_users(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_active_client?(conn) ->
            LiveView.Controller.live_render(conn, PmLoginWeb.Services.ClientUsersLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |>Login.not_active_client_redirection

      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def new(conn, _params) do
    changeset = Services.change_clients_request(%ClientsRequest{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"clients_request" => clients_request_params}) do
    case Services.create_clients_request(clients_request_params) do
      {:ok, clients_request} ->
        conn
        |> put_flash(:info, "Requête créée.")
        |> redirect(to: Routes.clients_request_path(conn, :show, clients_request))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    clients_request = Services.get_clients_request!(id)
    render(conn, "show.html", clients_request: clients_request)
  end

  def edit(conn, %{"id" => id}) do
    clients_request = Services.get_clients_request!(id)
    changeset = Services.change_clients_request(clients_request)
    render(conn, "edit.html", clients_request: clients_request, changeset: changeset)
  end

  def update(conn, %{"id" => id, "clients_request" => clients_request_params}) do
    clients_request = Services.get_clients_request!(id)

    case Services.update_clients_request(clients_request, clients_request_params) do
      {:ok, clients_request} ->
        conn
        |> put_flash(:info, "Requête mise à jour.")
        |> redirect(to: Routes.clients_request_path(conn, :show, clients_request))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", clients_request: clients_request, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    clients_request = Services.get_clients_request!(id)
    {:ok, _clients_request} = Services.delete_clients_request(clients_request)

    conn
    |> put_flash(:info, "Requête supprimée.")
    |> redirect(to: Routes.clients_request_path(conn, :index))
  end
end
