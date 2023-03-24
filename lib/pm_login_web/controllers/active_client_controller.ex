defmodule PmLoginWeb.ActiveClientController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Login

  alias Phoenix.LiveView


  def index(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
            active_clients = Services.list_active_clients()
            # render(conn, "index.html", active_clients: active_clients, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
            LiveView.Controller.live_render(conn, PmLogin.ActiveClient2.IndexLive, session: %{"active_clients" => active_clients, "curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> put_flash(:error, "Désolé, vous n'êtes pas administrateur!")
            |> redirect(to: Routes.user_path(conn, :index))

      end
    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.page_path(conn, :index))
    end

  end

  def new(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(conn, PmLogin.ActiveClient2.ActiveClientLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def create(conn, %{"active_client" => active_client_params}) do
    case Services.create_active_client(active_client_params) do
      {:ok, active_client} ->
        conn
        |> put_flash(:info, "Client actif créé.")
        |> redirect(to: Routes.active_client_path(conn, :show, active_client))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)

    end
  end

    #NOT USED
  # def show(conn, %{"id" => id}) do
  #   active_client = Services.get_active_client!(id)
  #   render(conn, "show.html", active_client: active_client)
  # end

    #NOT USED
  # def edit(conn, %{"id" => id}) do
  #   active_client = Services.get_active_client!(id)
  #   changeset = Services.change_active_client(active_client)
  #   render(conn, "edit.html", active_client: active_client, changeset: changeset)
  # end

  def update(conn, %{"id" => id, "active_client" => active_client_params}) do
    active_client = Services.get_active_client!(id)

    case Services.update_active_client(active_client, active_client_params) do
      {:ok, active_client} ->
        conn
        |> put_flash(:info, "Client actif mis à jour.")
        |> redirect(to: Routes.active_client_path(conn, :show, active_client))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", active_client: active_client, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    active_client = Services.get_active_client!(id)
    {:ok, _active_client} = Services.delete_active_client(active_client)

    conn
    |> put_flash(:info, "Client actif supprimé.")
    |> redirect(to: Routes.active_client_path(conn, :index))
  end

  def my_projects_clients_2(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_active_client?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Project.MyProjectsClients2Live, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

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

end
