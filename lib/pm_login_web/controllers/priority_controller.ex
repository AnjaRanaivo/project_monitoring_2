defmodule PmLoginWeb.PriorityController do
  use PmLoginWeb, :controller

  # alias PmLogin.Monitoring
  # alias PmLogin.Monitoring.Priority

  # def index(conn, _params) do
  #   priorities = Monitoring.list_priorities()
  #   render(conn, "index.html", priorities: priorities)
  # end

  # def new(conn, _params) do
  #   changeset = Monitoring.change_priority(%Priority{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{"priority" => priority_params}) do
  #   case Monitoring.create_priority(priority_params) do
  #     {:ok, priority} ->
  #       conn
  #       |> put_flash(:info, "Priority created successfully.")
  #       |> redirect(to: Routes.priority_path(conn, :show, priority))
  #
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   priority = Monitoring.get_priority!(id)
  #   render(conn, "show.html", priority: priority)
  # end

  # def edit(conn, %{"id" => id}) do
  #   priority = Monitoring.get_priority!(id)
  #   changeset = Monitoring.change_priority(priority)
  #   render(conn, "edit.html", priority: priority, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "priority" => priority_params}) do
  #   priority = Monitoring.get_priority!(id)
  #
  #   case Monitoring.update_priority(priority, priority_params) do
  #     {:ok, priority} ->
  #       conn
  #       |> put_flash(:info, "Priority updated successfully.")
  #       |> redirect(to: Routes.priority_path(conn, :show, priority))
  #
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", priority: priority, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   priority = Monitoring.get_priority!(id)
  #   {:ok, _priority} = Monitoring.delete_priority(priority)
  #
  #   conn
  #   |> put_flash(:info, "Priority deleted successfully.")
  #   |> redirect(to: Routes.priority_path(conn, :index))
  # end
  
end
