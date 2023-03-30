defmodule PmLoginWeb.Rights_clientsController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.Rights_clients

  def index(conn, _params) do
    rights_clients = Services.list_rights_clients()
    render(conn, "index.html", rights_clients: rights_clients)
  end

  def new(conn, _params) do
    changeset = Services.change_rights_clients(%Rights_clients{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"rights_clients" => rights_clients_params}) do
    case Services.create_rights_clients(rights_clients_params) do
      {:ok, rights_clients} ->
        conn
        |> put_flash(:info, "Rights clients created successfully.")
        |> redirect(to: Routes.rights_clients_path(conn, :show, rights_clients))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    rights_clients = Services.get_rights_clients!(id)
    render(conn, "show.html", rights_clients: rights_clients)
  end

  def edit(conn, %{"id" => id}) do
    rights_clients = Services.get_rights_clients!(id)
    changeset = Services.change_rights_clients(rights_clients)
    render(conn, "edit.html", rights_clients: rights_clients, changeset: changeset)
  end

  def update(conn, %{"id" => id, "rights_clients" => rights_clients_params}) do
    rights_clients = Services.get_rights_clients!(id)

    case Services.update_rights_clients(rights_clients, rights_clients_params) do
      {:ok, rights_clients} ->
        conn
        |> put_flash(:info, "Rights clients updated successfully.")
        |> redirect(to: Routes.rights_clients_path(conn, :show, rights_clients))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", rights_clients: rights_clients, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    rights_clients = Services.get_rights_clients!(id)
    {:ok, _rights_clients} = Services.delete_rights_clients(rights_clients)

    conn
    |> put_flash(:info, "Rights clients deleted successfully.")
    |> redirect(to: Routes.rights_clients_path(conn, :index))
  end
end
