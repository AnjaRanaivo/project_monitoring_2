defmodule PmLoginWeb.User.ClientEditPasswordLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Login

  def mount(_params, %{"curr_user_id" => curr_user_id, "user" => user,"changeset" => changeset}, socket) do
    Services.subscribe()
    layout = cond do
      Login.is_id_active_client?(curr_user_id) -> {PmLoginWeb.LayoutView, "active_client_layout_live.html"}
      true -> {PmLoginWeb.LayoutView, "client_layout_live.html"}
    end
    {:ok,
       socket
       |> assign(user: user, changeset: changeset,curr_user_id: curr_user_id, show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)),
       layout: layout
       }
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

  def render(assigns) do
   PmLoginWeb.UserView.render("edit_password.html", assigns)
  end

end
