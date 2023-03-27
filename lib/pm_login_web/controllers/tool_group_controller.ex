defmodule PmLoginWeb.ToolGroupController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.ToolGroup

  def index(conn, _params) do
    tool_groups = Services.list_tool_groups()
    render(conn, "index.html", tool_groups: tool_groups)
  end

  def new(conn, _params) do
    changeset = Services.change_tool_group(%ToolGroup{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"tool_group" => tool_group_params}) do
    case Services.create_tool_group(tool_group_params) do
      {:ok, tool_group} ->
        conn
        |> put_flash(:info, "Tool group created successfully.")
        |> redirect(to: Routes.tool_group_path(conn, :show, tool_group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    tool_group = Services.get_tool_group!(id)
    render(conn, "show.html", tool_group: tool_group)
  end

  def edit(conn, %{"id" => id}) do
    tool_group = Services.get_tool_group!(id)
    changeset = Services.change_tool_group(tool_group)
    render(conn, "edit.html", tool_group: tool_group, changeset: changeset)
  end

  def update(conn, %{"id" => id, "tool_group" => tool_group_params}) do
    tool_group = Services.get_tool_group!(id)

    case Services.update_tool_group(tool_group, tool_group_params) do
      {:ok, tool_group} ->
        conn
        |> put_flash(:info, "Tool group updated successfully.")
        |> redirect(to: Routes.tool_group_path(conn, :show, tool_group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", tool_group: tool_group, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tool_group = Services.get_tool_group!(id)
    {:ok, _tool_group} = Services.delete_tool_group(tool_group)

    conn
    |> put_flash(:info, "Tool group deleted successfully.")
    |> redirect(to: Routes.tool_group_path(conn, :index))
  end
end
