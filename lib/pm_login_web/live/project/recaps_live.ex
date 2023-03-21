defmodule PmLoginWeb.Project.RecapsLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.MyContex


  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    {:ok,
       socket
       |> assign(output_todays: MyContex.todays_dataset, output_month: MyContex.this_month_dataset, output_week: MyContex.this_week_dataset,todays: Monitoring.list_achieved_tasks_today, weeks: Monitoring.list_achieved_tasks_this_week, months: Monitoring.list_achieved_tasks_this_month)
       |> assign(curr_user_id: curr_user_id, show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
                  gantt_day: false, gantt_week: false, gantt_month: false),
       layout: {PmLoginWeb.LayoutView, "board_layout_live.html"}
       }
      end

    def handle_event("show_day", _params, socket), do: {:noreply, socket |> assign(gantt_day: true)}
    def handle_event("show_week", _params, socket), do: {:noreply, socket |> assign(gantt_week: true)}
    def handle_event("show_month", _params, socket), do: {:noreply, socket |> assign(gantt_month: true)}

    def handle_event("close_day", _params, socket), do: {:noreply, socket |> assign(gantt_day: false)}
    def handle_event("close_week", _params, socket), do: {:noreply, socket |> assign(gantt_week: false)}
    def handle_event("close_month", _params, socket), do: {:noreply, socket |> assign(gantt_month: false)}

      def handle_event("key_cancel", %{"key" => key}, socket) do
        case key do
          "Escape" ->
            {:noreply, socket |> assign(gantt_day: false, gantt_week: false, gantt_month: false)}
            _ ->
            {:noreply, socket}

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

  def handle_info({Monitoring, [:project, :updated], _}, socket) do
    {:noreply, socket |> assign(todays: Monitoring.list_achieved_tasks_today, weeks: Monitoring.list_achieved_tasks_this_week, months: Monitoring.list_achieved_tasks_this_month,
    output_todays: MyContex.todays_dataset, output_month: MyContex.this_month_dataset, output_week: MyContex.this_week_dataset)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def handle_info({Monitoring, [:status, :updated], _}, socket) do
    {:noreply, socket |> assign(todays: Monitoring.list_achieved_tasks_today, weeks: Monitoring.list_achieved_tasks_this_week, months: Monitoring.list_achieved_tasks_this_month,
    output_todays: MyContex.todays_dataset, output_month: MyContex.this_month_dataset, output_week: MyContex.this_week_dataset)}
  end

  def handle_info({Monitoring, [:task, :updated], _}, socket) do
    {:noreply, socket |> assign(todays: Monitoring.list_achieved_tasks_today, weeks: Monitoring.list_achieved_tasks_this_week, months: Monitoring.list_achieved_tasks_this_month,
    output_todays: MyContex.todays_dataset, output_month: MyContex.this_month_dataset, output_week: MyContex.this_week_dataset)}
  end

  def render(assigns) do
   PmLoginWeb.ProjectView.render("recaps.html", assigns)
  end
end
