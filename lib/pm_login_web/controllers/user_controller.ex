defmodule PmLoginWeb.UserController do
  use PmLoginWeb, :controller

  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Login.Right
  alias PmLogin.Login.Auth
  alias Phoenix.LiveView
  alias PmLogin.Monitoring

  def index(conn, _params) do

    # current_id = get_session(conn, :curr_user_id)

    if Login.is_connected?(conn) do
      # current_user = Login.get_user!(current_id)
        cond do
          # old working main admin route
          # Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          # new main admin route
          Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.MainAdminIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_attributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_contributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_active_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ActiveClientIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_not_attributed?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

          Login.is_archived?(conn) -> conn |> put_flash(:error, "Votre compte a été archivé!")|> delete_session(:curr_user_id) |>redirect(to: Routes.page_path(conn, :index))

          true -> redirect(conn, to: Routes.page_path(conn, :index))
        end

      else
        conn
        |> put_flash(:error, "Connectez-vous d'abord!")
        |> redirect(to: Routes.page_path(conn, :index))
    end

    #OLD ROUTE
    # auths = Login.list_all_auth
    # render(conn, "index.html", users: auths)
  end

  def admin_space(conn, _paras) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminIndexLive, session: %{"current_user" => Login.get_curr_user(conn),"curr_user_id" => Login.get_curr_user(conn).id}, router: PmLoginWeb.Router)

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

  def list(conn, _params) do
    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          LiveView.Controller.live_render(conn, PmLoginWeb.User.ListLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

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
    changeset = Login.change_user(%User{})
    render(conn, "new.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "register_layout.html"})
  end

  def create(conn, %{"user" => user_params}) do
    case Login.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Bienvenue, #{user.username}, vous vous êtes bien inscrit.")
        |> put_session(:curr_user_id, user.id)
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "register_layout.html"})
    end
  end

  def show(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      user = Login.get_curr_user_id(conn) |> Login.get_auth!
      case user.right_id do
        # 1 -> render(conn, "show.html", user: user, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
        1 -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminProfileLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
        2 -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorProfileLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
        3 -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorProfileLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
        4 -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientProfileLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
        5 -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedProfileLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

        _ -> render(conn, "show.html", user: user)
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def edit_password(conn, %{"id" => id}) do
    if Login.is_connected?(conn) do
      user = Login.get_curr_user(conn)
      changeset = Login.change_user(user)
      cond do
          # Login.is_admin?(conn) -> render(conn, "edit_profile.html", user: user, changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_attributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_contributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_unattributed?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          true -> render(conn, "edit_profile.html", user: user, changeset: changeset)
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def edit_profile(conn, %{"id" => id}) do
    # current_id = get_session(conn, :curr_user_id)
    if Login.is_connected?(conn) do
      user = Login.get_curr_user(conn)
      changeset = Login.change_user(user)
      cond do
          # Login.is_admin?(conn) -> render(conn, "edit_profile.html", user: user, changeset: changeset, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
          Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_attributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_contributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          Login.is_unattributed?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
          true -> render(conn, "edit_profile.html", user: user, changeset: changeset)
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.page_path(conn, :index))
    end

  end

  # defp map_str_rights(%Right{} = r) do
  #   if r.id != 7 do
  #       {String.to_atom(r.title), r.id}
  #   end
  # end

  def edit(conn, %{"id" => id}) do
    if Login.is_connected?(conn) do

      current_user = Login.get_curr_user(conn)
      user = Login.get_user!(id)
      cond do
         Login.is_admin?(conn) ->
           # changeset = Login.change_user(user)
           # rights = Login.list_rights_without_archived
           # str_rights = Enum.map(rights, fn (%Right{} = r)  -> {String.to_atom(r.title), r.id} end)
           # render(conn, "edit.html", user: user, changeset: changeset, rights: rights, str_rights: str_rights, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
           LiveView.Controller.live_render(conn, PmLoginWeb.User.EditLive, session: %{"user" => user,"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)

         true ->
         conn
         |> put_flash(:error, "Vous n'êtes pas administrateur!")
         |> redirect(to: Routes.user_path(conn, :index))
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.page_path(conn, :index))
    end

  end

  def update_profile(conn, %{"id" => id, "user" => user_params}) do
    user = Login.get_user!(id)

    IO.puts "update_profile"
    IO.inspect user_params

    case Login.update_profile(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Profil mis à jour.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "edit_profile.html", user: user, changeset: changeset)
        cond do
          Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_attributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_contributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_unattributed?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedEditprofileLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          true -> render(conn, "edit_profile.html", user: user, changeset: changeset)
        end
    end
  end

  def update_password(conn, %{"id" => id, "user" => user_params}) do
    user = Login.get_user!(id)

    case Login.update_password(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Mot de passe mis à jour.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "edit_profile.html", user: user, changeset: changeset)
        cond do
          Login.is_admin?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AdminEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_attributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.AttributorEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_contributor?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ContributorEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_client?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.ClientEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          Login.is_unattributed?(conn) -> LiveView.Controller.live_render(conn, PmLoginWeb.User.UnattributedEditPasswordLive, session: %{"user" => user,"changeset" => changeset,"curr_user_id" => get_session(conn, :curr_user_id)})
          true -> render(conn, "edit_profile.html", user: user, changeset: changeset)
        end
    end
  end



  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Login.get_user!(id)

    # IO.inspect user_params

    case Login.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Profil mis à jour.")
        |> redirect(to: Routes.user_path(conn, :edit, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def restore(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do

      cond do
        Login.is_admin?(conn) ->
          user = Login.get_user!(id)
          {:ok, _user} = Login.restore_user(user)

          conn
          |> put_flash(:info, "Utilisateur #{user.username} restauré(e).")
          |> redirect(to: Routes.user_path(conn, :list))

        true ->
          conn
          |> put_flash(:error, "Vous n'êtes pas administrateur!")
          |> redirect(to: Routes.user_path(conn, :index))
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.user_path(conn, :index))
    end
  end

  def archive(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          user = Login.get_user!(id)
          Login.archive_user(user)

          conn
          |> put_flash(:info, "Utilisateur #{user.username} archivé(e).")
          |> redirect(to: Routes.user_path(conn, :list))

        true ->
          conn
          |> put_flash(:error, "Vous n'êtes pas administrateur!")
          |> redirect(to: Routes.user_path(conn, :index))
      end

    else
      conn
      |> put_flash(:error, "Connectez-vous d'abord!")
      |> redirect(to: Routes.user_path(conn, :index))
    end

  end

  #NOT USED YET FOR NOW
  # A DELETE_USER FUNCTION

  # def delete(conn, %{"id" => id}) do
  #   current_id = get_session(conn, :curr_user_id)
  #
  #   if current_id != nil do
  #     current_user = Login.get_user!(current_id)
  #     case current_user.right_id do
  #       1 ->
  #         user = Login.get_user!(id)
  #         {:ok, _user} = Login.delete_user(user)
  #
  #         conn
  #         |> put_flash(:info, "Utilisateur #{user.username} archivé(e).")
  #         |> redirect(to: Routes.user_path(conn, :list))
  #
  #       _ ->
  #         conn
  #         |> put_flash(:error, "Vous n'êtes pas administrateur!")
  #         |> redirect(to: Routes.user_path(conn, :index))
  #     end
  #
  #   else
  #     conn
  #     |> put_flash(:error, "Connectez-vous d'abord!")
  #     |> redirect(to: Routes.user_path(conn, :index))
  #   end
  #
  # end


end
