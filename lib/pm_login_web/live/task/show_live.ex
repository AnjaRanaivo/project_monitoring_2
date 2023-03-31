defmodule PmLoginWeb.Task.ShowLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Login

  def mount(_params, %{"curr_user_id"=>curr_user_id, "id"=>id}, socket) do
    Monitoring.subscribe()

    Services.subscribe()
    Services.subscribe_to_request_topic()
    task = Monitoring.get_task_by_id(id)
    layout =
      case Login.get_user!(curr_user_id).right_id do
        1 -> {PmLoginWeb.LayoutView, "board_layout_live.html"}
        2 -> {PmLoginWeb.LayoutView, "attributor_board_live.html"}
        3 -> {PmLoginWeb.LayoutView, "contributor_board_live.html"}
        _ -> {}
      end
    {:ok,
       socket
       |> assign(
       form: false, curr_user_id: curr_user_id, show_notif: false,id: id,
       task: task,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)),
       layout: layout
       }

  end

  def render(assigns) do
    PmLoginWeb.TaskView.render("show.html", assigns)
   end
end
