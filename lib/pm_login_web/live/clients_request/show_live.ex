defmodule PmLoginWeb.ClientsRequest.ShowLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring

  def mount(_params, %{"curr_user_id"=>curr_user_id, "id"=>id}, socket) do
    Monitoring.subscribe()

    Services.subscribe()
    Services.subscribe_to_request_topic()
    client_request = Monitoring.get_clients_request_by_id(id)
    layout =
    case Services.get_active_client_from_userid!(curr_user_id).rights_clients_id do
      1 -> {PmLoginWeb.LayoutView, "active_client_admin_layout_live.html"}
      2 -> {PmLoginWeb.LayoutView, "active_client_demandeur_layout_live.html"}
      3 -> {PmLoginWeb.LayoutView, "active_client_utilisateur_layout_live.html"}
      _ -> {}
    end
    {:ok,
       socket
       |> assign(
       form: false, curr_user_id: curr_user_id, show_notif: false,id: id,client_request: client_request,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)),
       layout: layout
       }

  end

  def render(assigns) do
    PmLoginWeb.ClientsRequestView.render("show.html", assigns)
   end

end
