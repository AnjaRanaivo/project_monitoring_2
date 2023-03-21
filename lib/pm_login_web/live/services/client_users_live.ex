defmodule PmLoginWeb.Services.ClientUsersLive do
  use PmLoginWeb, :live_view

  alias PmLogin.Services
  alias PmLoginWeb.ClientsRequestView

  alias PmLogin.Login
  alias PmLogin.Login.{User}
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.{Task, Priority}
  alias PmLogin.Services

  #=======#
  # Mount #
  #=======#
  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    Monitoring.subscribe()

    statuses = Monitoring.list_statuses()

    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})

    priorities = Monitoring.list_priorities()
    list_priorities = Enum.map(priorities, fn %Priority{} = p -> {p.title, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    # IO.puts "HOLAAA"
    active_client_id = Services.get_ac_id_from_user_id(curr_user_id)

    # IO.inspect(active_client_id)
    active_client = Services.get_active_client_from_userid!(curr_user_id)
    # IO.inspect(active_client)
    associated_active_clients = Services.list_active_clients_by_company_id(active_client.company_id)
    # IO.inspect associated_active_clients

    socket =
      socket
      |> assign(acs: associated_active_clients)
      |> assign(active_client_id: active_client_id)
      |> assign(curr_user_id: curr_user_id)
      |> assign(show_notif: false)
      |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, 4))

    {:ok, socket, layout: {PmLoginWeb.LayoutView, "active_client_layout_live.html"}}
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

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length

    {:noreply,
     socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  #========#
  # Render #
  #========#
  def render(assigns) do
    ClientsRequestView.render("client_users.html", assigns)
  end
end
