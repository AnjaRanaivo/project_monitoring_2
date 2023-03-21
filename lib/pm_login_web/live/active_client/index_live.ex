defmodule PmLogin.ActiveClient.IndexLive do
  use Phoenix.LiveView
  alias PmLogin.{Services, Login}

  def mount(_params, %{"curr_user_id" => curr_user_id,"active_clients" => active_clients}, socket) do
    Services.subscribe()

    {:ok,
       socket
       |> assign(active_clients: active_clients,
                curr_user_id: curr_user_id,
                show_notif: false,
                notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
                active_clients_selected: true),
       layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
       }
  end

  def handle_event("filter-client", params, socket) do
    IO.puts "TAFIDITRA FILTER"
    case params["client_selection"] do
      "1" ->
        {:noreply, socket |> assign(active_clients: Services.list_active_clients(), active_clients_selected: true)}

      _ ->
        {:noreply, socket |> assign(active_clients: Login.list_non_active_clients(), active_clients_selected: false)}
    end
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
   PmLoginWeb.ActiveClientView.render("index.html", assigns)
  end
end
