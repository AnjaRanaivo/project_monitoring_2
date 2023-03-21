defmodule PmLoginWeb.Services.RequestsLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLoginWeb.LiveComponent.ModalLive
  alias PmLoginWeb.LiveComponent.DetailModalRequestLive
  alias PmLoginWeb.Router.Helpers, as: Routes

  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Services.subscribe()
    Services.subscribe_to_request_topic()

    {:ok,
       socket
       |> assign(search_text: nil)
       |> assign(requests: Services.list_requests, show_detail_request_modal: false, client_request: nil,
       show_modal: false, service_id: nil,curr_user_id: curr_user_id,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)),
       layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
       }
  end

  #==============================#
  # Showing Survey Request Event #
  #==============================#
  def handle_event("show_survey_request", _params, socket) do
    {:noreply, socket |> redirect(to: Routes.clients_request_path(socket, :survey))}
  end

  def handle_event("modal_close", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("request-search", params, socket) do
    search = params["request_search"]

    requests = Services.search_my_request!(search)

    socket =
      socket
      |> assign(requests: requests)
      |> assign(search_text: search)

    {:noreply, socket}
  end

  def handle_event("request-status", params, socket) do
    status = params["status_id"]

    requests = Services.list_my_requests_by_status(status)

    socket =
      socket
      |> assign(requests: requests)

    {:noreply, socket}
  end

  def handle_event("switch-seen", params, socket) do

    bool = case params["value"] do
    "on" -> true
      _ -> false
    end

    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"seen" => bool})

    text_vu = case bool do
      true -> "vue"
      _ -> "non vue"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} a été #{text_vu}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("show_detail_request_modal", %{"id" => id}, socket) do
    client_request = Services.list_clients_requests_with_client_name_and_id(id)

    {:noreply, socket |> assign(show_detail_request_modal: true, client_request: client_request)}
  end

  def handle_info({DetailModalRequestLive, :button_clicked, %{action: "cancel", param: nil}}, socket) do
    {:noreply, assign(socket, show_detail_request_modal: false)}
  end

  def handle_event("switch-ongoing", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"ongoing" => bool})

    text_encours = case bool do
      true -> "est en cours"
      _ -> "n\'est pas en cours"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} #{text_encours}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("switch-done", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"done" => bool})

    text_accomplie = case bool do
      true -> "accomplie"
      _ -> "non accomplie"
    end
    curr_user_id = socket.assigns.curr_user_id

    notif_text = "Requête #{request.title} #{text_accomplie}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text, 8)
    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_info({"request_topic", [:request, :updated], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
  end

  def handle_info({"request_topic", [:request, :sent], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
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
    editors = Services.list_all_editors
    {:noreply, socket |> assign(editors: editors)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def render(assigns) do
   PmLoginWeb.ClientsRequestView.render("requests.html", assigns)
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
      editor = Services.get_editor!(service_id)
      Services.delete_editor(editor)
      # PmLoginWeb.UserController.archive(socket, user.id)
  {:noreply,
    socket
    |> put_flash(:info, "L'éditeur' #{editor.title} a bien été supprimé!")
    |> push_event("AnimateAlert", %{})
    |> assign(show_modal: false)
      }
  end

  def handle_event("go-del", %{"id" => id}, socket) do
    # Phoenix.LiveView.get_connect_info(socket)
    # put_session(socket, del_id: id)
    {:noreply, assign(socket, show_modal: true, service_id: id)}
  end

end
