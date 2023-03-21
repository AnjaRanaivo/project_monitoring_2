defmodule PmLoginWeb.CompanyController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.Company
  alias PmLogin.Login
  alias Phoenix.LiveView

  def index(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          # companies = Services.list_companies()
          # render(conn, "index.html", companies: companies, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Company.IndexLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def services(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.IndexLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def my_company(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_active_client?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.MyCompanyLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_active_client_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def new(conn, _params) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          changeset = Services.change_company(%Company{})
          # render(conn, "new.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Company.NewLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id),"changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def create(conn, %{"company" => company_params}) do
    case Services.create_company(company_params) do
      {:ok, company} ->
        conn
        |> put_flash(:info, "Société enregistrée.")
        |> redirect(to: Routes.company_path(conn, :show, company))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "new.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
        LiveView.Controller.live_render(conn, PmLoginWeb.Company.NewLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id),"changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def show(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          # company = Services.get_company!(id)
          # render(conn, "show.html", company: company, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Company.ShowLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id),"company_id" => id}, router: PmLoginWeb.Router)

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
        Login.is_admin?(conn) ->
          company = Services.get_company!(id)
          changeset = Services.change_company(company)
          # render(conn, "edit.html", company: company, changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn, PmLoginWeb.Company.EditLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "company" => company, "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def update(conn, %{"id" => id, "company" => company_params}) do
    company = Services.get_company!(id)

    case Services.update_company(company, company_params) do
      {:ok, company} ->
        conn
        |> put_flash(:info, "Société mise à jour.")
        |> redirect(to: Routes.company_path(conn, :show, company))

      {:error, %Ecto.Changeset{} = changeset} ->
        LiveView.Controller.live_render(conn, PmLoginWeb.Company.EditLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "company" => company, "changeset" => changeset}, router: PmLoginWeb.Router)
    end
  end

  def delete(conn, %{"id" => id}) do
    company = Services.get_company!(id)
    {:ok, _company} = Services.delete_company(company)

    conn
    |> put_flash(:info, "Société enregistrée")
    |> redirect(to: Routes.company_path(conn, :index))
  end
end
