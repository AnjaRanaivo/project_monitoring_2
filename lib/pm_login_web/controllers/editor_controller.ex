defmodule PmLoginWeb.EditorController do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.Editor
  alias Phoenix.LiveView
  alias PmLogin.Login

  def index(conn, _params) do
    # render(conn, "index.html", editors: editors)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          editors = Services.list_all_editors()
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "editors" => editors}, router: PmLoginWeb.Router)

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
          changeset = Services.change_editor(%Editor{})
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewEditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def create(conn, %{"editor" => editor_params}) do
    case Services.create_editor(editor_params) do
      {:ok, editor} ->
        conn
        |> put_flash(:info, "Editeur créé.")
        |> redirect(to: Routes.editor_path(conn, :show, editor))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "new.html", changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewEditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def show(conn, %{"id" => id}) do
    # render(conn, "show.html", editor: editor)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          editor = Services.get_editor_with_company!(id)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.ShowEditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "editor" => editor}, router: PmLoginWeb.Router)

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

    # render(conn, "edit.html", editor: editor, changeset: changeset)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          editor = Services.get_editor!(id)
          changeset = Services.change_editor(editor)
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditEditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "editor" => editor, "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def update(conn, %{"id" => id, "editor" => editor_params}) do
    editor = Services.get_editor!(id)

    case Services.update_editor(editor, editor_params) do
      {:ok, editor} ->
        IO.inspect editor_params
        conn
        |> put_flash(:info, "Editeur mis à jour.")
        |> redirect(to: Routes.editor_path(conn, :show, editor))

      {:error, %Ecto.Changeset{} = changeset} ->
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditEditorLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "editor" => editor, "changeset" => changeset}, router: PmLoginWeb.Router)
        # render(conn, "edit.html", editor: editor, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    editor = Services.get_editor!(id)
    {:ok, _editor} = Services.delete_editor(editor)

    conn
    |> put_flash(:info, "Editeur supprimé")
    |> redirect(to: Routes.editor_path(conn, :index))
  end

end
