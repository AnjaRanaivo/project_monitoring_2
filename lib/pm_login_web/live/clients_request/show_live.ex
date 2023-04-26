defmodule PmLoginWeb.ClientsRequest.ShowLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Login
  alias PmLoginWeb.Router.Helpers, as: Routes
   alias PmLogin.Services.ClientsRequest

  def mount(_params, %{"curr_user_id"=>curr_user_id, "id"=>id}, socket) do
    Monitoring.subscribe()

    Services.subscribe()
    Services.subscribe_to_request_topic()
    client_request = Monitoring.get_clients_request_by_id(id)
    changeset2 = Services.change_clients_request(%ClientsRequest{})
    layout = case Monitoring.is_admin?(curr_user_id) do
      true -> {PmLoginWeb.LayoutView, "board_layout_live.html"}
      false -> case Services.get_active_client_from_userid!(curr_user_id).rights_clients_id do
          1 -> {PmLoginWeb.LayoutView, "active_client_admin_layout_live.html"}
          2 -> {PmLoginWeb.LayoutView, "active_client_demandeur_layout_live.html"}
          3 -> {PmLoginWeb.LayoutView, "active_client_utilisateur_layout_live.html"}
          _ -> {}
        end
    end
    # layout =
    # case Services.get_active_client_from_userid!(curr_user_id).rights_clients_id do
    #   1 -> {PmLoginWeb.LayoutView, "active_client_admin_layout_live.html"}
    #   2 -> {PmLoginWeb.LayoutView, "active_client_demandeur_layout_live.html"}
    #   3 -> {PmLoginWeb.LayoutView, "active_client_utilisateur_layout_live.html"}
    #   _ -> {}
    # end
    {:ok,
       socket
       |> assign(
       form: false, curr_user_id: curr_user_id, show_notif: false,id: id,client_request: client_request,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
       changeset: changeset2) |> allow_upload(:file,
       accept:
         ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .csv .xml .xls .xlsx .ppt .pptx .doc .docx),
       max_entries: 5
     ),
       layout: layout
       }

  end

  def render(assigns) do
    PmLoginWeb.ClientsRequestView.render("show.html", assigns)
   end

  def handle_event("change-request", params, socket) do
    IO.inspect("------------------------")
    {:noreply, socket}
  end

  def handle_event("update-file", _params, socket) do
    consume_uploaded_entries(socket, :file, fn meta, entry ->
      ext = Path.extname(entry.client_name)
      file_name = Path.basename(entry.client_name, ext)
      dest = Path.join("priv/static/uploads", "#{file_name}#{entry.uuid}#{ext}")
      File.cp!(meta.path, dest)
    end)

    {entries, []} = uploaded_entries(socket, :file)

    IO.inspect("---------------------------------")

    urls =
      for entry <- entries do
        ext = Path.extname(entry.client_name)
        file_name = Path.basename(entry.client_name, ext)
        Routes.static_path(socket, "/uploads/#{file_name}#{entry.uuid}#{ext}")
      end

      IO.inspect(socket.assigns.client_request.file_urls ++ urls)

    Services.update_request_files(socket.assigns.client_request, %{"file_urls" => socket.assigns.client_request.file_urls ++ urls})
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:file, ref)}
  end

end
