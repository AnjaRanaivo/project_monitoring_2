defmodule PmLoginWeb.LicenseController do
  use PmLoginWeb, :controller
  alias Phoenix.LiveView

  alias PmLogin.Services
  alias PmLogin.Services.License
  alias PmLogin.Login

  def index(conn, _params) do
    # render(conn, "index.html", licenses: licenses)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          licenses = Services.list_licenses_with_company
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.LicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "licenses" => licenses}, router: PmLoginWeb.Router)

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
          changeset = Services.change_license(%License{})
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewLicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def create(conn, %{"license" => license_params}) do
    case Services.create_license(license_params) do
      {:ok, license} ->
        conn
        |> put_flash(:info, "Licence créee.")
        |> redirect(to: Routes.license_path(conn, :show, license))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "new.html", changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewLicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def show(conn, %{"id" => id}) do
    # render(conn, "show.html", license: license)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          license = Services.get_license_with_company!(id)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.ShowLicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "license" => license}, router: PmLoginWeb.Router)

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

    # render(conn, "edit.html", license: license, changeset: changeset)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          license = Services.get_license!(id)
          changeset = Services.change_license(license)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditLicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "license" => license, "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def update(conn, %{"id" => id, "license" => license_params}) do
    license = Services.get_license!(id)

    case Services.update_license(license, license_params) do
      {:ok, license} ->
        conn
        |> put_flash(:info, "Licence mise à jour.")
        |> redirect(to: Routes.license_path(conn, :show, license))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "edit.html", license: license, changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditLicenseLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "license" => license, "changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def delete(conn, %{"id" => id}) do
    license = Services.get_license!(id)
    {:ok, _license} = Services.delete_license(license)

    conn
    |> put_flash(:info, "Licence supprimée.")
    |> redirect(to: Routes.license_path(conn, :index))
  end

end
