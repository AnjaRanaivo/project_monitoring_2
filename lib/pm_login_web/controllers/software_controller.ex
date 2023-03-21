defmodule PmLoginWeb.SoftwareController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.Software
  alias Phoenix.LiveView
  alias PmLogin.Login

  def index(conn, _params) do
    # render(conn, "index.html", softwares: softwares)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          softwares = Services.list_softwares_with_company
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.SoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "softwares" => softwares}, router: PmLoginWeb.Router)

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
    # render(conn, "new.html", changeset: changeset)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          changeset = Services.change_software(%Software{})
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewSoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def create(conn, %{"software" => software_params}) do
    case Services.create_software(software_params) do
      {:ok, software} ->
        conn
        |> put_flash(:info, "Infos de logiciel enregistré.")
        |> redirect(to: Routes.software_path(conn, :show, software))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "new.html", changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewSoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def show(conn, %{"id" => id}) do
    # render(conn, "show.html", software: software)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          software = Services.get_software_with_company!(id)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.ShowSoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "software" => software}, router: PmLoginWeb.Router)

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

    # render(conn, "edit.html", software: software, changeset: changeset)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          software = Services.get_software!(id)
          changeset = Services.change_software(software)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditSoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id),"software"=>software ,"changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def update(conn, %{"id" => id, "software" => software_params}) do
    software = Services.get_software!(id)

    case Services.update_software(software, software_params) do
      {:ok, software} ->
        conn
        |> put_flash(:info, "Infos sur le logiciel mis à jours avec succès.")
        |> redirect(to: Routes.software_path(conn, :show, software))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "edit.html", software: software, changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditSoftwareLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id),"software"=>software ,"changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def delete(conn, %{"id" => id}) do
    software = Services.get_software!(id)
    {:ok, _software} = Services.delete_software(software)

    conn
    |> put_flash(:info, "Infos de logiciel supprimé.")
    |> redirect(to: Routes.software_path(conn, :index))
  end

end
