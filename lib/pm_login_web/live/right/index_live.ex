defmodule PmLoginWeb.Right.IndexLive do
  use Phoenix.LiveView
  alias PmLogin.Login
  alias PmLoginWeb.RightView
  alias PmLoginWeb.RightController
  alias PmLoginWeb.LiveComponent.ModalLive
  alias PmLogin.Services


  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Login.subscribe()
   {:ok,
      socket
      |> assign(curr_user_id: curr_user_id,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4))
      |> fetch,
      layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
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

  def handle_info({Login, [:right | _], _}, socket) do
    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    assign(socket, rights: Login.list_asc_rights(),show_modal: false, del_id: nil)
  end


  def render(assigns) do
   RightView.render("index.html", assigns)
  end


  #modal_component

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-del"}},
      socket
    ) do
  {:noreply, assign(socket, show_modal: false)}
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "delete", param: del_id}},
      socket
    ) do
      right = Login.get_right!(del_id)
      Login.delete_right(right)
  {:noreply,
    socket
    |> assign(show_modal: false)
      }
  end

  def handle_event("go-del", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_modal: true, del_id: id)}
  end

end
