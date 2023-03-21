defmodule PmLoginWeb.RightController do
  use PmLoginWeb, :controller

  alias PmLogin.Login
  alias PmLogin.Login.Right
  alias Phoenix.LiveView


  def index(conn, _params) do
    current_id = get_session(conn, :curr_user_id)
    if current_id != nil do
      current_user = Login.get_user!(current_id)
      case current_user.right_id do
        1 ->
          rights = Login.list_asc_rights()
          LiveView.Controller.live_render(conn,PmLoginWeb.Right.IndexLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)})
          # render(conn, "index.html", rights: rights, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})

        _ ->
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
    current_id = get_session(conn, :curr_user_id)
    if current_id != nil do
      current_user = Login.get_user!(current_id)
      case current_user.right_id do
        1 ->
          changeset = Login.change_right(%Right{})
          # render(conn, "new.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn,PmLoginWeb.Right.NewLive, session: %{"changeset" => changeset, "curr_user_id" => get_session(conn, :curr_user_id)})

        _ ->
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

  def create(conn, %{"right" => right_params}) do
    case Login.create_right(right_params) do
      {:ok, right} ->
        conn
        |> put_flash(:info, "Statut crée.")
        |> redirect(to: Routes.right_path(conn, :show, right))

      {:error, %Ecto.Changeset{} = changeset} ->
        LiveView.Controller.live_render(conn,PmLoginWeb.Right.NewLive, session: %{"changeset" => changeset, "curr_user_id" => get_session(conn, :curr_user_id)})
    end
  end

  def show(conn, %{"id" => id}) do
    current_id = get_session(conn, :curr_user_id)
    if current_id != nil do
      current_user = Login.get_user!(current_id)
      case current_user.right_id do
        1 ->
          right = Login.get_right!(id)
          # render(conn, "show.html", right: right, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          LiveView.Controller.live_render(conn,PmLoginWeb.Right.ShowLive, session: %{"right" => right, "curr_user_id" => get_session(conn, :curr_user_id)})

        _ ->
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

  def edit(conn, %{"id" => id}) do
    current_id = get_session(conn, :curr_user_id)
    if current_id != nil do
      current_user = Login.get_user!(current_id)
      case current_user.right_id do
        1 ->
          right = Login.get_right!(id)
          changeset = Login.change_right(right)
          render(conn, "edit.html", right: right, changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
        _ ->
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

  def update(conn, %{"id" => id, "right" => right_params}) do
    right = Login.get_right!(id)

    case Login.update_right(right, right_params) do
      {:ok, right} ->
        conn
        |> put_flash(:info, "Statut mis à jour.")
        |> redirect(to: Routes.right_path(conn, :show, right))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", right: right, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_id = get_session(conn, :curr_user_id)
    if current_id != nil do
      current_user = Login.get_user!(current_id)
      case current_user.right_id do
        1 ->
          right = Login.get_right!(id)
          {:ok, _right} = Login.delete_right(right)

          conn
          |> put_flash(:info, "Statut supprimé")
          |> redirect(to: Routes.right_path(conn, :index))

        _ ->
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



end
