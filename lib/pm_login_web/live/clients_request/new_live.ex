defmodule PmLoginWeb.ClientsRequest.NewLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Services.ClientsRequest
  alias PmLogin.Services.RequestType
  alias PmLogin.Services.ToolGroup
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Services
  alias PmLogin.Services.Company
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Uuid
  alias PmLoginWeb.Router.Helpers, as: Routes


  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Monitoring.subscribe()

    Services.subscribe()
    Services.subscribe_to_request_topic()
    request_types = Monitoring.list_request_types()
    request_type_ids = Enum.map(request_types, fn(%RequestType{} = rt) -> {rt.name, rt.id} end )
    tool_groups = Monitoring.list_tools_group_by_user_id(curr_user_id)
    tool_group_ids = Enum.map(tool_groups, fn(%ToolGroup{} = tg) -> {tg.name, tg.id} end )
    tools = Monitoring.list_tools()
    changeset2 = Services.change_clients_request(%ClientsRequest{})
    selected_tool = ''
    selected_tool_id = 0
    layout =
    case Services.get_active_client_from_userid!(curr_user_id).rights_clients_id do
      1 -> {PmLoginWeb.LayoutView, "active_client_admin_layout_live.html"}
      2 -> {PmLoginWeb.LayoutView, "active_client_demandeur_layout_live.html"}
      3 -> {PmLoginWeb.LayoutView, "active_client_utilisateur_layout_live.html"}
      _ -> {}
    end
    {:ok,
       socket
       |> assign(request_type_ids: request_type_ids, tool_group_ids: tool_group_ids, selected_tool: selected_tool,
       selected_tool_id: selected_tool_id,
       tool_groups: tool_groups,tools: tools, changeset: changeset2,
       form: false, curr_user_id: curr_user_id, show_notif: false,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4))|> allow_upload(:file,
       accept:
         ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .csv .xml .xls .xlsx .ppt .pptx .doc .docx),
       max_entries: 5
     ),
       layout: layout
       }
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:file, ref)}
  end

  def handle_event("change-selected-tool", %{"tool" => tool}, socket) do
    tool_obj = Monitoring.get_tool_by_id(tool)
    {:noreply, socket |> assign(selected_tool: tool_obj.name, selected_tool_id: tool)}
  end

  def handle_event("change-request", params, socket) do
    IO.inspect(socket)
    {:noreply, socket}
  end

  def handle_event("send-request", %{"clients_request" => params}, socket) do
    # Added uuid to the current params
    params = Map.put_new(params, "uuid", Uuid.generate)
    params = Map.put_new(params, "tool_id", socket.assigns.selected_tool_id)
    IO.inspect(params)

    {entries, []} = uploaded_entries(socket, :file)
    # IO.inspect(entries)

    # urls = for entry <- entries do
    #   Routes.static_path(socket, "/uploads/#{entry.uuid}#{Path.extname(entry.client_name)}")
    # end

    # IO.inspect urls

    # consume_uploaded_entries(socket, :file, fn meta, entry ->
    #   dest = Path.join("priv/static/uploads", "#{entry.uuid}#{Path.extname(entry.client_name)}")
    #   File.cp!(meta.path, dest)
    #  end)
    # IO.inspect socket.assigns.uploads[:file].entries

    case Services.create_clients_request_2(params) do
      {:ok, result} ->
        consume_uploaded_entries(socket, :file, fn meta, entry ->
          ext = Path.extname(entry.client_name)
          file_name = Path.basename(entry.client_name, ext)
          dest = Path.join("priv/static/uploads", "#{file_name}#{entry.uuid}#{ext}")
          File.cp!(meta.path, dest)
        end)

        {entries, []} = uploaded_entries(socket, :file)

        urls =
          for entry <- entries do
            ext = Path.extname(entry.client_name)
            file_name = Path.basename(entry.client_name, ext)
            Routes.static_path(socket, "/uploads/#{file_name}#{entry.uuid}#{ext}")
          end

        Services.update_request_files(result, %{"file_urls" => urls})

        {:ok, result} |> Services.broadcast_request()
        # sending notifs to admins
        curr_user_id = socket.assigns.curr_user_id
        the_client = Services.get_active_client_from_userid!(curr_user_id)

        Services.send_notifs_to_admins(
          curr_user_id,
          "Le client #{the_client.user.username} de la société #{the_client.company.name} a envoyé une requête intitulée \"#{result.title}\".",
          5
        )

        Monitoring.broadcast_clients_requests({:ok, :clients_requests})

        {:noreply,
         socket
         |> assign(
           display_form: false,
           changeset: Services.change_clients_request(%ClientsRequest{}
           ),
           selected_tool: '',
           selected_tool_id: 0
         )
         |> put_flash(:info, "Requête envoyée")
         |> push_event("AnimateAlert", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  def render(assigns) do
   PmLoginWeb.ClientsRequestView.render("new.html", assigns)
  end
end
