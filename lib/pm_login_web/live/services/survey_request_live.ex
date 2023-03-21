defmodule PmLoginWeb.Services.SurveyRequestLive do
  use PmLoginWeb, :live_view

  alias PmLogin.Services
  alias PmLoginWeb.ClientsRequestView

  alias PmLogin.Utilities

  # ====== Mount ======#
  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Services.subscribe_to_request_topic()

    #================================================#
    # Show loading when socket is not been connected #
    #================================================#
    if not connected?(socket) do
      Process.send_after(self(), :socket_not_connected, 0)
    end

    socket =
      socket
      |> assign(
        request: nil,
        date_begin: "",
        date_end: "",
        date_begin_formatted: "",
        date_end_formatted: "",
        request_count: 0,
        data_chart: %{
          values: []
        },
        active_clients: Services.list_active_clients(),
        loading: false,
        search_text: nil,
        requests: Services.list_requests(),
        show_detail_request_modal: false,
        client_request: nil,
        show_modal: false,
        service_id: nil,
        curr_user_id: curr_user_id,
        show_notif: false,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)
      )

    {:ok, socket, layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}}
  end

  #================================================#
  # Show loading when socket is not been connected #
  #================================================#
  def handle_info(:socket_not_connected, socket) do
    {:noreply, socket |> assign(loading: true)}
  end

  #===========================#
  # Switch notification event #
  #===========================#
  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id

    switch =
      if socket.assigns.show_notif do
        ids =
          socket.assigns.notifs
          |> Enum.filter(fn x -> !x.seen end)
          |> Enum.map(fn x -> x.id end)

        Services.put_seen_some_notifs(ids)
        false
      else
        true
      end

    {:noreply,
     socket
     |> assign(
       show_notif: switch,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length)
     )}
  end

  #============================#
  # Loading notification event #
  #============================#
  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length

    {:noreply,
     socket
     |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length + 4))
     |> push_event("SpinTest", %{})}
  end

  #===========================#
  # Cancel notification event #
  #===========================#
  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  #=======================#
  # Search survey request #
  #=======================#
  def handle_event("search-survey-request", params, socket) do
    date_begin = params["date_begin"]
    date_end = params["date_end"]

    request = Services.get_all_client_request_between_date(date_begin, date_end)

    request_count =
      if Enum.count(request) >= 10, do: Enum.count(request), else: "0#{Enum.count(request)}"

    if not connected?(socket) do
      Process.send_after(self(), :socket_not_connected, 0)
    end

    date_begin_formatted =
      date_begin
      |> Date.from_iso8601!()
      |> Utilities.date_to_naive()
      |> Utilities.letters_date_format_without_days()

    date_end_formatted =
      date_end
      |> Date.from_iso8601!()
      |> Utilities.date_to_naive()
      |> Utilities.letters_date_format_without_days()

    created_tools_status =
      for req <- request do
        cond do
          req.survey["created_tools"]["status"] in ["Non", "Plus ou moins"] ->
            0

          true ->
            1
        end
      end

    time_saved_status =
      for req <- request do
        cond do
          req.survey["time_saved"]["status"] in ["Non", "Plus ou moins"] ->
            0

          true ->
            1
        end
      end

    deadline_communicated_status =
      for req <- request do
        cond do
          req.survey["deadline_communicated"]["status"] in ["Non", "Plus ou moins"] ->
            0

          true ->
            1
        end
      end

    team_response_status =
      for req <- request do
        cond do
          req.survey["team_response"]["status"] in ["Non", "Plus ou moins"] ->
            0

          true ->
            1
        end
      end

    values =
      case String.to_integer(request_count) do
        0 -> []
        _ ->
          [
            trunc(Enum.sum(created_tools_status) / String.to_integer(request_count) * 100),
            trunc(Enum.sum(time_saved_status)  / String.to_integer(request_count) * 100),
            trunc(Enum.sum(deadline_communicated_status) / String.to_integer(request_count) * 100),
            trunc(Enum.sum(team_response_status) / String.to_integer(request_count) * 100)
          ]
      end

    {:noreply,
      socket
      |> assign(
        request: request,
        date_begin: date_begin,
        date_end: date_end,
        date_begin_formatted: date_begin_formatted,
        date_end_formatted: date_end_formatted,
        request_count: request_count,
        data_chart: %{
          values: values
        }
      )
    }
  end

  # ====== Render ======#
  def render(assigns) do
    ClientsRequestView.render("survey_request.html", assigns)
  end
end
