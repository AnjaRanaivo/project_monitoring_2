defmodule PmLoginWeb.TaskController do
  use PmLoginWeb, :controller

  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Task

  # def index(conn, _params) do
  #   tasks = Monitoring.list_tasks()
  #   render(conn, "index.html", tasks: tasks)
  # end

  # def new(conn, _params) do
  #   changeset = Monitoring.change_task(%Task{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  def create(conn, %{"task" => task_params}) do
    case Monitoring.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Tâche créée.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # def show(conn, %{"id" => id}) do
  #   task = Monitoring.get_task!(id)
  #   render(conn, "show.html", task: task)
  # end

  # def edit(conn, %{"id" => id}) do
  #   task = Monitoring.get_task!(id)
  #   changeset = Monitoring.change_task(task)
  #   render(conn, "edit.html", task: task, changeset: changeset)
  # end

  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Monitoring.get_task!(id)

    case Monitoring.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Tâche mise à jour.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", task: task, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Monitoring.get_task!(id)
    {:ok, _task} = Monitoring.delete_task(task)

    conn
    |> put_flash(:info, "Tâche supprimée.")
    |> redirect(to: Routes.task_path(conn, :index))
  end
end
