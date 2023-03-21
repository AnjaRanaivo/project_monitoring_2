defmodule PmLoginWeb.User.ListLive do
  use Phoenix.LiveView
  alias PmLogin.Login
  alias PmLoginWeb.UserView
  alias PmLoginWeb.UserController
  alias PmLoginWeb.LiveComponent.ModalLive
  alias PmLogin.Login.Auth
  alias PmLogin.Services
  alias PmLogin.Login.User

  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Login.subscribe()
    changeset = Login.change_user(%User{})
   {:ok,
      socket
      |> assign(changeset: changeset,form: false,curr_user_id: curr_user_id, show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4))
      |> fetch,
      layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
      }
  end

  def handle_event("save-user", %{"user" => params}, socket) do
    # IO.inspect(params)
    case Login.create_user(params) do
      {:ok, user} ->
        Login.broadcast_user_creation({:ok, user})
        {:noreply, socket |> put_flash(:info, "L'utilisateur #{params["username"]} a été créé") |> assign(form: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end

  end

  def handle_info({Login, [:user, :created], _}, socket) do
    {:noreply, socket |> assign(users: Login.list_asc_auth())}
  end

  def handle_info({Services, [:active_client, :created], _}, socket) do
    {:noreply, socket |> assign(users: Login.list_asc_auth())}
  end

  def handle_event("show-form", _params, socket), do: {:noreply, socket|>assign(form: true)}
  def handle_event("close-form", _params, socket), do: {:noreply, socket|>assign(form: false)}

  def handle_event("cancel-form", %{"key" => key}, socket) do
    case key do
      "Escape" ->
        {:noreply, socket |> assign(form: false)}
        _ ->
        {:noreply, socket}
    end
  end

  # Pour fixer l'erreur qui remet la page à se recharger
  def handle_event("cancel-form", %{}, socket) do
    {:noreply, socket}
  end

  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id
    switch = if socket.assigns.show_notif do
              ids = socket.assigns.notifs
                    |> Enum.filter(fn(x) -> !(x.seen) end)
                    |> Enum.map(fn(x) -> x.id  end)
              Services.put_seen_some_notifs(ids)
                false
              else
                true
             end
    {:noreply, socket |> assign(show_notif: switch, notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length))}
  end

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4)) |> push_event("SpinTest", %{})}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def handle_info({Login, [:user | _], _}, socket) do
    {:noreply, fetch(socket)}
  end

  def handle_info({Login, [:right | _], _}, socket) do
    {:noreply, fetch(socket)}
  end

  def handle_event("switch", %{"id" => id}, socket) do
    {:noreply, assign(socket, users: Login.filter_auth(id))}
  end

  def handle_event("test_filter", _, socket) do
    {:noreply, assign(socket, users: Login.filter_auth(1))}
  end

  def handle_event("sorted_by_status", _,socket) do
    auth = socket.assigns.users

    case socket.assigns.sorted_by_status do
        true -> {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.right_id), :desc), sorted_by_status: false)}
        _ ->  {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.right_id)), sorted_by_status: true)}
    end

  end

  def handle_event("sorted_by_email", _,socket) do
    auth = socket.assigns.users

    case socket.assigns.sorted_by_email do
        true -> {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.email), :desc), sorted_by_email: false)}
        _ ->  {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.email)), sorted_by_email: true)}
    end

  end

  def handle_event("sorted_by_username", _,socket) do
    auth = socket.assigns.users

    case socket.assigns.sorted_by_username do
        true -> {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.username), :desc), sorted_by_username: false)}
        _ ->  {:noreply, socket |> assign(users: Enum.sort_by(auth, &(&1.username)), sorted_by_username: true)}
    end

  end

  def handle_event("search-user", %{"_target" => ["search-a"], "search-a" => text}, socket) do
    new_auth = Enum.filter(Login.list_asc_auth(), fn %Auth{} = x -> Login.filter_username(text,x.username) end)
    {:noreply, assign(socket, users: new_auth)}
  end

  def handle_event("sort_users", %{"_target" => ["sort_select"], "sort_select" => sort_type}, socket), do:
    {:noreply, assign(socket, users: Login.sort_auth(sort_type))}

  def handle_event("sort_users", %{"_target" => ["sort_select"]},socket), do:
    {:noreply, socket}

  def handle_event("right_selected", %{"_target" => ["right_select"], "right_select" => id}, socket) do
    IO.inspect id
    {:noreply, assign(socket, users: Login.filter_auth(id |> String.to_integer))}
  end

  def handle_event("right_selected", %{"_target" => ["right_select"]}, socket), do:
    {:noreply, socket}

  def handle_event("arch", %{"id" => id}, socket) do
    user = Login.get_user!(id)
    Login.archive_user(user)
    # Log.delete_user(user)

    {:noreply, put_flash(socket, :info, "L'utilisateur #{user.username} a bien été archivé") |> push_event("AnimateAlert", %{})}
  end

  defp fetch(socket) do
    assign(socket, users: Login.list_asc_auth(), rights: Login.list_rights(),sorted_by_username: false , sorted_by_email: false, sorted_by_status: false,show_modal: false, arch_id: nil)
  end

  def render(assigns) do
   UserView.render("index.html", assigns)
  end

  #modal_component

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-arch"}},
      socket
    ) do
  {:noreply, assign(socket, show_modal: false)}
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "arch", param: arch_id}},
      socket
    ) do
      user = Login.get_user!(arch_id)
      Login.archive_user(user)
      # PmLoginWeb.UserController.archive(socket, user.id)
  {:noreply,
    socket
    |> put_flash(:info, "L'utilisateur #{user.username} a bien été archivé!")
    |> assign(show_modal: false)
      }
  end

  def handle_event("go-arch", %{"id" => id}, socket) do
    # Phoenix.LiveView.get_connect_info(socket)
    # put_session(socket, del_id: id)
    {:noreply, assign(socket, show_modal: true, arch_id: id)}
  end


end
