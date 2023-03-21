defmodule PmLogin.ActiveClient.ActiveClientLive do
  use Phoenix.LiveView

  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Services
  alias PmLogin.Services.{Company, ActiveClient}
  alias PmLoginWeb.LiveComponent.ModalLive

  def mount(_params, %{"curr_user_id" => curr_user_id}, socket) do
    Services.subscribe()
    {:ok, assign(socket,curr_user_id: curr_user_id, show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4), show_modal: false, params: nil,inactives: Login.list_non_active_clients,
                companies: Enum.map(Services.list_companies, fn %Company{} = c -> {c.name, c.id} end)
                ), layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
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

  def handle_info(
      {ModalLive, :button_clicked, %{action: "confirm-activate", param: params}},
      socket
    ) do
      params |> Services.create_active_client
  {:noreply,
    socket
    |> put_flash(:info, "Le client #{PmLogin.Login.get_user!(params["user_id"]).username} a bien été rendu actif et affilié à #{PmLogin.Services.get_company!(params["company_id"]).name}!")
    |> push_event("AnimateAlert", %{})
    |> assign(show_modal: false)
      }
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-active", param: _}},
      socket
    ) do
  {:noreply,
    socket
    |> assign(show_modal: false)
      }
  end

  def handle_event("activate_c", %{"client_id" => client_id, "my_form" => %{"company_id" => company_id}}, socket) do
    IO.puts client_id
    IO.puts company_id
    params = %{"user_id" => client_id, "company_id" => company_id}
    IO.inspect params
    # Services.create_active_client(%{"user_id" => client_id, "company_id" => company_id})
    {:noreply, assign(socket, params: params, show_modal: true)}
  end

  def handle_info({Services, [:active_client, :created], _}, socket) do
    {:noreply, assign(socket,  inactives: Login.list_non_active_clients)}
  end

  def render(assigns) do
    PmLoginWeb.ActiveClientView.render("new.html", assigns)
  end
end
