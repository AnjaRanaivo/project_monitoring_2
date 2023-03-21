defmodule PmLoginWeb.User.UnattributedIndexLive do
  use Phoenix.LiveView
  alias PmLogin.Services

  def mount(_params, %{"curr_user_id"=>curr_user_id, "current_user" => current_user}, socket) do
    Services.subscribe()

    {:ok,
       socket
       |> assign(curr_user_id: curr_user_id,current_user: current_user),
       layout: {PmLoginWeb.LayoutView, "unattributed_layout_live.html"}
       }
  end

  # def handle_event("switch-notif", %{}, socket) do
  #   notifs_length = socket.assigns.notifs |> length
  #   curr_user_id = socket.assigns.curr_user_id
  #   switch = if socket.assigns.show_notif do
  #             ids = socket.assigns.notifs
  #                   |> Enum.filter(fn(x) -> !(x.seen) end)
  #                   |> Enum.map(fn(x) -> x.id  end)
  #             Services.put_seen_some_notifs(ids)
  #               false
  #             else
  #               true
  #            end
  #   {:noreply, socket |> assign(show_notif: switch, notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length))}
  # end

  # def handle_event("load-notifs", %{}, socket) do
  #   curr_user_id = socket.assigns.curr_user_id
  #   notifs_length = socket.assigns.notifs |> length
  #   {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4))}
  # end

  # def handle_event("cancel-notif", %{}, socket) do
  #   cancel = if socket.assigns.show_notif, do: false
  #   {:noreply, socket |> assign(show_notif: cancel)}
  # end

  # def handle_info({Services, [:notifs, :sent], _}, socket) do
  #   curr_user_id = socket.assigns.curr_user_id
  #   length = socket.assigns.notifs |> length
  #   {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  # end

  def render(assigns) do
   PmLoginWeb.UserView.render("unattributed_index.html", assigns)
  end

end
