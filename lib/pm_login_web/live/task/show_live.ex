defmodule PmLoginWeb.Task.ShowLive do
  use Phoenix.LiveView
  alias PmLoginWeb.LiveComponent.CommentsModalLive
  alias PmLoginWeb.LiveComponent.ModifModalLive
  alias PmLoginWeb.LiveComponent.CommentsModalMenu
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Login
  alias PmLogin.Kanban
  alias PmLogin.Monitoring.Comment
  alias PmLogin.Monitoring.Task
  alias PmLogin.Monitoring.Priority
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Login.User

  def mount(_params, %{"curr_user_id"=>curr_user_id, "id"=>id}, socket) do
    Monitoring.subscribe()

    Services.subscribe()
    Services.subscribe_to_request_topic()
    task = Monitoring.get_task_by_id(id)
    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})
    priorities = Monitoring.list_priorities()
    list_priorities = Enum.map(priorities, fn %Priority{} = p -> {p.title, p.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

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
       show_comments_modal: false,
       show_comments_menu: false,
       card_with_comments: nil,
       pro_id: task.project_id,
       priorities: list_priorities,
       attributors: list_attributors,
       is_admin: Monitoring.is_admin?(curr_user_id),
       is_contributor: Monitoring.is_contributor?(curr_user_id),
       is_attributor: Monitoring.is_attributor?(curr_user_id),
       card: nil,
       show_modif_modal: false,
       task_changeset: task_changeset,
       contributors: list_contributors,
       modif_changeset: modif_changeset,
       comment_changeset: Monitoring.change_comment(%Comment{}),
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4))
       |> allow_upload(:file,
         accept:
           ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .csv .xml .xls .xlsx .ppt .pptx .doc .docx),
         max_entries: 5
       ),
       layout: layout
       }

  end

  def handle_event("update_task", %{"task" => params}, socket) do
    # progression to int
    # IO.puts "OIIIIIIIIII"
    # IO.inspect params

    hour = String.to_integer(params["hour"])
    hour_p = String.to_integer(params["hour_performed"])
    minutes = String.to_integer(params["minutes"])
    minutes_p = String.to_integer(params["minutes_performed"])

    total_minutes = hour * 60 + minutes
    total_minutes_p = hour_p * 60 + minutes_p

    # Ajouter la durée estimée dans le map
    params =
      params
      |> Map.put("estimated_duration", total_minutes)
      |> Map.put("performed_duration", total_minutes_p)

    int_progression = params["progression"] |> Float.parse() |> elem(0) |> trunc
    attrs = %{params | "progression" => int_progression}
    # UPDATING
    task = Monitoring.get_task!(params["task_id"])
    # IO.inspect params
    # IO.inspect task
    # IO.inspect Monitoring.update_task(task, params)
    case Monitoring.update_task(task, attrs) do
      {:ok, updated_task} ->
        current_card = Monitoring.get_task_with_card!(updated_task.id).card
        Kanban.update_card(current_card, %{name: updated_task.title})
        # IO.inspect task
        # IO.inspect attrs
        {:ok, updated_task} |> Monitoring.broadcast_updated_task()

        # IO.inspect {:ok, task}
        # IO.inspect {:ok, updated_task}

        if is_nil(task.contributor_id) and not is_nil(updated_task.contributor_id) do
          Services.send_notif_to_one(
            updated_task.attributor_id,
            updated_task.contributor_id,
            "#{Login.get_user!(updated_task.contributor_id).username} a été assigné à la tâche #{updated_task.title} par #{Login.get_user!(updated_task.attributor_id).username}",
            6
          )

          Services.send_notifs_to_admins(
            updated_task.attributor_id,
            "#{Login.get_user!(updated_task.contributor_id).username} a été assigné à la tâche #{updated_task.title} par #{Login.get_user!(updated_task.attributor_id).username}",
            6
          )
        end

        {:noreply,
         socket
         |> put_flash(:info, "Tâche #{updated_task.title} mise à jour")
         |> assign(show_modif_modal: false)
         |> assign(show_modif_menu: false)
         |> push_event("AnimateAlert", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        # IO.inspect changeset
        # IO.inspect changeset.errors
        {:noreply, socket |> assign(modif_changeset: changeset)}
    end
  end

  def handle_event("change-comment", params, socket) do
    # IO.inspect params
    {:noreply, socket}
  end

  def handle_event("send-comment", %{"comment" => params}, socket) do
    # IO.puts task_id
    # IO.puts poster_id
    # IO.puts content

    {entries, []} = uploaded_entries(socket, :file)
    # IO.inspect entries

    case Monitoring.post_comment(params) do
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

        Monitoring.update_comment_files(result, %{"file_urls" => urls})

        card_id = socket.assigns.card_with_comments.id
        nb_com = socket.assigns.com_nb
        {:ok, result} |> Monitoring.broadcast_com()

        {:noreply,
         socket
         |> assign(
           comment_changeset: Monitoring.change_comment(%Comment{}),
           card_with_comments: Kanban.get_card_for_comment_limit!(card_id, nb_com),
           com_nb: nb_com
         )
         |> push_event("updateScroll", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        card_id = socket.assigns.card_with_comments.id
        nb_com = socket.assigns.com_nb

        {:noreply,
         socket |> assign(comment_changeset: changeset) |> push_event("updateScroll", %{})}
    end
  end

  def handle_event("show_comments_modal", %{"id" => id}, socket) do
    # IO.puts id
    # IO.puts "com modal showed"
    IO.puts(id)
    com_nb = 5
    card = Kanban.get_card_for_comment_limit!(id, com_nb)
    # card = ordered |> Enum.reverse
    {:noreply,
     socket
     |> assign(show_comments_modal: true, card_with_comments: card, com_nb: com_nb)
     |> push_event("updateScroll", %{})}
  end

  def handle_event("show_modif_modal", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)
    {:noreply, socket |> assign(show_modif_modal: true, card: card)}
  end

  def handle_info({CommentsModalLive, :button_clicked, %{action: "cancel-comments"}}, socket) do
    {:noreply, assign(socket, show_comments_modal: false)}
  end

  def handle_info({CommentsModalMenu, :button_clicked, %{action: "cancel-comments"}}, socket) do
    {:noreply, assign(socket, show_comments_menu: false)}
  end

  def handle_info({Monitoring, [:comment, :posted], _}, socket) do
    card_id = socket.assigns.card_with_comments.id
    nb_com = socket.assigns.com_nb

    {:noreply,
     socket
     |> assign(
       card_with_comments: Kanban.get_card_for_comment_limit!(card_id, nb_com),
       com_nb: nb_com
     )
     |> push_event("updateScroll", %{})}
  end

  def handle_info({ModifModalLive, :button_clicked, %{action: "cancel-modif"}}, socket) do
    # task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_modif_modal: false, modif_changeset: modif_changeset)}
  end

  def render(assigns) do
    PmLoginWeb.TaskView.render("show.html", assigns)
   end
end
