defmodule PmLoginWeb.Services.SoftwareLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLoginWeb.LiveComponent.ModalLive

  def mount(_params, %{"curr_user_id"=>curr_user_id, "softwares" => softwares}, socket) do
    Services.subscribe()

    {:ok,
       socket
       |> assign(show_modal: false, service_id: nil,curr_user_id: curr_user_id,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4), softwares: softwares),
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

  def handle_info({Services, [_, :deleted], _}, socket) do
    softwares = Services.list_softwares_with_company
    {:noreply, socket |> assign(softwares: softwares)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def render(assigns) do
   PmLoginWeb.SoftwareView.render("index.html", assigns)
  end

  #del modal component

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-del"}},
      socket
    ) do
  {:noreply, assign(socket, show_modal: false)}
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "del", param: service_id}},
      socket
    ) do
      software = Services.get_software!(service_id)
      Services.delete_software(software)
      # PmLoginWeb.UserController.archive(socket, user.id)
  {:noreply,
    socket
    |> put_flash(:info, "Info logiciel de #{software.title} supprimé!")
    |> push_event("AnimateAlert", %{})
    |> assign(service_id: nil,show_modal: false)
      }
  end

  def handle_event("go-del", %{"id" => id}, socket) do
    # Phoenix.LiveView.get_connect_info(socket)
    # put_session(socket, del_id: id)
    {:noreply, assign(socket, show_modal: true, service_id: id)}
  end

end
