defmodule PmLoginWeb.Project.ContributorTasksLive do
  use Phoenix.LiveView

  import Phoenix.HTML.Link
  # import Phoenix.HTML.Form

  # Importer les composants nécessaires
  alias PmLoginWeb.LiveComponent.{
    PlusModalLive,
    ModifModalMenu,
    CommentsModalMenu
  }

  alias PmLogin.Monitoring
  alias PmLogin.Kanban
  alias PmLogin.Monitoring.{Task, Priority, Planified}
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Services
  alias PmLogin.Monitoring.Comment
  alias PmLoginWeb.Router.Helpers, as: Routes

  def mount(_params, %{"curr_user_id" => curr_user_id, "tasks" => tasks}, socket) do
    Monitoring.subscribe()
    Services.subscribe()

    statuses = Monitoring.list_statuses_for_tasks_table()

    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})

    priorities = Monitoring.list_priorities()
    list_priorities = Enum.map(priorities, fn %Priority{} = p -> {p.title, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    secondary_changeset = Monitoring.change_task(%Task{})

    planified_changeset = Monitoring.change_planified(%Planified{})

    {:ok,
     socket
     |> assign(
       tasks: tasks,
       curr_user_id: curr_user_id,
       statuses: statuses,
       show_notif: false,
       tasks_not_achieved: Monitoring.list_tasks_not_achieved_for_contributor(curr_user_id),
       is_attributor: Monitoring.is_attributor?(curr_user_id),
       is_admin: Monitoring.is_admin?(curr_user_id),
       contributors: list_contributors,
       attributors: list_attributors,
       priorities: list_priorities,
       planified_changeset: planified_changeset,
       is_contributor: Monitoring.is_contributor?(curr_user_id),
       task_changeset: task_changeset,
       modif_changeset: modif_changeset,
       secondary_changeset: secondary_changeset,
       comment_changeset: Monitoring.change_comment(%Comment{}),

       # Par défault, on n'affiche pas show_plus_modal
       show_modif_menu: false,
       show_comments_menu: false,
       show_plus_modal: false,
       card_with_comments: nil,
       card: nil,
       notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)
     )
     |> allow_upload(:file,
       accept:
         ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .csv .xml .xls .xlsx .ppt .pptx .doc .docx),
       max_entries: 5
     ), layout: {PmLoginWeb.LayoutView, "contributor_layout_live.html"}}
  end

  def handle_event("status_and_progression_changed", params, socket) do
    if params["progression_change"] == nil or params["progression_change"] == "" do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "La progression doit être comprise entre 0 à 100")
       |> push_event("AnimateAlert", %{})}
    else
      progression = params["progression_change"] |> Float.parse() |> elem(0) |> trunc

      if progression < 0 or progression > 100 do
        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:error, "La progression doit être comprise entre 0 à 100")
         |> push_event("AnimateAlert", %{})}
      else
        task = Monitoring.get_task_with_card!(params["task_id"])

        # Récupérer l'id de la dernière stage
        stage_end_id = Monitoring.get_achieved_stage_id_from_project_id!(task.project_id)

        curr_user_id = socket.assigns.curr_user_id

        status_id = params["status_id"]

        project = Monitoring.get_project_with_tasks!(task.project_id)

        Kanban.put_card_to_achieve(
          task.card,
          %{
            "stage_id" =>
              case status_id do
                "1" -> stage_end_id - 4
                "2" -> stage_end_id - 3
                "3" -> stage_end_id - 2
                "4" -> stage_end_id - 1
                _ -> nil
              end
          }
        )

        Monitoring.update_task(task, %{"status_id" => status_id})
        Monitoring.update_task_progression(task, %{"progression" => params["progression_change"]})

        Monitoring.broadcast_progression_change({:ok, task})

        if Monitoring.is_a_child?(task) do
          Monitoring.update_mother_task_progression(task, curr_user_id)
        end

        if Monitoring.is_task_primary?(task) do
          Monitoring.add_progression_to_project(project)
        end

        if Monitoring.is_task_mother?(task) do
          Monitoring.achieve_children_tasks(task, curr_user_id)
        end

        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:info, "#{task.card.name} mise à jour.")
         |> push_event("AnimateAlert", %{})}
      end
    end
  end

  # Afficher le modal détails du tâche
  def handle_event("show_plus_modal", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)

    {:noreply,
     socket
     |> clear_flash()
     |> assign(show_plus_modal: true, card: card)
     |> assign(show_modif_menu: false, card: card)
     |> assign(show_comments_menu: false, card: card)}
  end

  # Afficher le modal des commentaires
  def handle_event("show_comments_menu", %{"id" => id}, socket) do
    card_menu = Kanban.get_card_from_modal!(id)
    com_nb = 5
    card = Kanban.get_card_for_comment_limit!(id, com_nb)

    {:noreply,
     socket
     |> assign(show_comments_menu: true, card_with_comments: card, com_nb: com_nb)
     |> push_event("updateScroll", %{})
     |> assign(show_plus_modal: false, card: card_menu)
     |> assign(show_modif_menu: false, card: card_menu)}
  end

  # Afficher le modal de la modification des tâches
  def handle_event("show_modif_menu", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)

    {:noreply,
     socket
     |> assign(show_modif_menu: true, card: card)
     |> assign(show_plus_modal: false, card: card)
     |> assign(show_comments_menu: false, card: card)}
  end

  # Recharger la liste des commentaires
  def handle_event("load_comments", %{}, socket) do
    card_id = socket.assigns.card_with_comments.id
    nb_com = socket.assigns.com_nb + 5

    card = Kanban.get_card_for_comment_limit!(card_id, nb_com)

    {:noreply,
     socket
     |> assign(com_nb: nb_com, card_with_comments: card)
     |> push_event("SpinComment", %{})}
  end

  # Scroller la liste des commentaires
  def handle_event("scroll-bot", %{}, socket) do
    {:noreply, socket |> push_event("updateScroll", %{})}
  end

  # Envoyer les commentaires
  def handle_event("send-comment", %{"comment" => params}, socket) do
    {entries, []} = uploaded_entries(socket, :file)

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

  # Quand, on tape quelque chose dans le label du commentaire
  def handle_event("change-comment", params, socket) do
    {:noreply, socket}
  end

  # Afficher le modal de la modification des tâches
  def handle_event("show_modif_menu", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)

    {:noreply,
     socket
     |> assign(show_modif_menu: true, card: card)
     |> assign(show_plus_modal: false, card: card)
     |> assign(show_comments_menu: false, card: card)}
  end

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

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length

    {:noreply,
     socket
     |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length + 4))
     |> push_event("SpinTest", %{})}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  # Mettre à jour les modifications des tâches
  def handle_event("update_task", %{"task" => params}, socket) do
    hour        = String.to_integer(params["hour"])
    hour_p      = String.to_integer(params["hour_performed"])
    minutes     = String.to_integer(params["minutes"])
    minutes_p   = String.to_integer(params["minutes_performed"])

    total_minutes   = (hour * 60) + minutes
    total_minutes_p = (hour_p * 60) + minutes_p

    # Ajouter la durée estimée dans le map
    params =
      params
      |> Map.put("estimated_duration", total_minutes)
      |> Map.put("performed_duration", total_minutes_p)

    int_progression = params["progression"] |> Float.parse() |> elem(0) |> trunc
    attrs = %{params | "progression" => int_progression}

    task = Monitoring.get_task!(params["task_id"])

    case Monitoring.update_task(task, attrs) do
      {:ok, updated_task} ->
        current_card = Monitoring.get_task_with_card!(updated_task.id).card
        Kanban.update_card(current_card, %{name: updated_task.title})

        {:ok, updated_task} |> Monitoring.broadcast_updated_task()

        if is_nil(task.contributor_id) and not is_nil(updated_task.contributor_id) do
          Services.send_notif_to_one(
            updated_task.attributor_id,
            updated_task.contributor_id,
            "#{Login.get_user!(updated_task.attributor_id).username} vous a assigné à la tâche #{updated_task.title}.",
            6
          )

          Services.send_notifs_to_admins(
            updated_task.attributor_id,
            "#{Login.get_user!(updated_task.attributor_id).username} vous a assigné à la tâche #{updated_task.title}.",
            6
          )
        end

        {:noreply,
         socket
         |> put_flash(:info, "Tâche #{updated_task.title} mise à jour")
         |> assign(show_modif_modal: false)
         |> assign(show_modif_menu: false)
         |> push_event("AnimateAlert", %{})
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(modif_changeset: changeset)}
    end
  end

  def handle_info({Monitoring, [_, _], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    tasks = Monitoring.list_tasks_by_contributor_project(curr_user_id)

    tasks_not_achieved = Monitoring.list_tasks_not_achieved_for_contributor(curr_user_id)

    IO.puts("handle_info...")

    {:noreply, socket |> assign(tasks: tasks, tasks_not_achieved: tasks_not_achieved)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length

    {:noreply,
     socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  # Quitter le modal des commentaires
  def handle_info({CommentsModalMenu, :button_clicked, %{action: "cancel-comments"}}, socket) do
    {:noreply, assign(socket, show_comments_menu: false)}
  end

  # Quitter le modal de la modification des tâches
  def handle_info({ModifModalMenu, :button_clicked, %{action: "cancel-modif"}}, socket) do
    # task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_modif_menu: false, modif_changeset: modif_changeset)}
  end

  # Quitter le modal de l'affichage des détails
  def handle_info({PlusModalLive, :button_clicked, %{action: "cancel-plus"}}, socket) do
    # task_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_plus_modal: false)}
  end

  # Appliquer les changements lorsqu'une tâche a été mise à jour
  def handle_info({Monitoring, [:task, :updated], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id

    my_primary_tasks = Monitoring.list_primary_tasks(socket.assigns.board.project.id)
    list_primaries = my_primary_tasks |> Enum.map(fn %Task{} = p -> {p.title, p.id} end)

    {:noreply, assign(socket, primaries: list_primaries)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <!-- <h3>
        <i class="bi bi-list-task"></i>
        Les tâches qui m'ont été assigné
      </h3> -->

      <!-- Appel du composant PlusModalLive -->
        <%= live_component(PlusModalLive,
                          id: "confirm-arch" ,
                          title: "Tâche" ,
                          body: nil,
                          right_button: nil,
                          right_button_action: nil,
                          right_button_param: nil,
                          left_button: "Retour" ,
                          left_button_action: "cancel-plus" ,
                          show_plus_modal: @show_plus_modal,
                          card: @card)
        %>

      <!-- Appel du composant ModifModalMenu -->
        <%= live_component(ModifModalMenu,
                          id: "confirm-arch" ,
                          title: "Modifier tâche" ,
                          body: nil,
                          right_button: nil,
                          right_button_action: nil,
                          right_button_param: nil,
                          left_button: "Retour" ,
                          left_button_action: "cancel-modif" ,
                          task_changeset: @task_changeset,
                          curr_user_id: @curr_user_id,
                          modif_changeset: @modif_changeset,
                          priorities: @priorities,
                          contributors: @contributors,
                          attributors: @attributors,
                          is_admin: @is_admin,
                          is_contributor: @is_contributor,
                          is_attributor: @is_attributor,
                          show_modif_menu: @show_modif_menu,
                          card: @card)
         %>

      <!-- Appel du composant CommentsModalMenu -->
        <%= live_component(CommentsModalMenu,
                          id: "confirm-arch" ,
                          title: "Commentaires" ,
                          body: nil,
                          right_button: "Oui" ,
                          right_button_action: "arch" ,
                          right_button_param: "" ,
                          left_button: "Annuler" ,
                          left_button_action: "cancel-comments" ,
                          curr_user_id: @curr_user_id,
                          changeset: @comment_changeset,
                          show_comments_menu: @show_comments_menu,
                          uploads: @uploads,
                          card: @card_with_comments)
        %>

      <%= if @tasks_not_achieved == [] do %>
        <div class="alert-primary" role="alert">
          <i class="bi bi-info-circle" style="font-size: 20px"></i>
          <div class="alert-text"> Aucune tâche n'a été assignée pour le moment... </div>
        </div>
      <% else %>
        <table class="table-tasks" id="" style="font-size: 11px;">
          <thead>
            <tr>
              <th>Projet</th>
              <th>Nom</th>
              <!-- <th>Description</th> -->
              <th>Statut</th>
              <th>Priorité</th>
              <th>Date de début</th>
              <th>Date d'échéance</th>
              <th>Progression</th>
            </tr>
          </thead>
          <tbody>
            <%= for task <- @tasks do %>
              <!-- Afficher les tâches si son statut est différent de Achevée(s) et que c'est pas archivé -->
              <%= if task.status_id != 5 and task.hidden == false do %>
                <tr>
                  <td data-label="Projet">
                    <%= link "#{task.project.title}", to: Routes.project_path(@socket, :board, task.project_id) %>
                  </td>
                  <td data-label="Nom" style="word-wrap: anywhere; min-width: 150px;">
                    <%= task.title %>
                  </td>
                  <!-- <td data-label="Description" style="word-wrap: anywhere"><%= task.description %></td> -->
                  <form phx-submit="status_and_progression_changed" style="margin-top: 23px;">
                    <td data-label="Status" style="min-width: 100px;">
                      <input type="hidden" value={task.id} name="task_id"/>
                      <input type="hidden" value={task.card} name="card_id" />
                      <select name="status_id" id="status_change_id" style="color: #fff;">
                          <%= for status <- @statuses do %>
                            <%= if status.id == task.status.id do %>
                              <option value={status.id} style="background: #1F2937; color: #fff;" selected>
                                <%= status.title %>
                              </option>
                            <% else %>
                              <option value={status.id} style="background: #1F2937; color: #fff;">
                                <%= status.title %>
                              </option>
                            <% end %>
                          <% end %>
                      </select>
                    </td>
                    <td data-label="Priorité" style="min-width: 150px;">
                      <%= case task.priority_id do %>
                        <% 1 -> %>
                          <div class="low__priority__point__bg">
                            <span class="low__priority__point__t"></span>
                            Faible
                          </div>
                        <% 2 -> %>
                          <div class="avg__priority__point__bg">
                            <span class="avg__priority__point__t"></span>
                            Moyenne
                          </div>
                        <% 3 -> %>
                          <div class="high__priority__point__bg">
                            <span class="high__priority__point__t"></span>
                            Importante
                          </div>
                        <% 4 -> %>
                          <div class="urg__priority__point__bg">
                            <span class="urg__priority__point__t"></span>
                            Urgente
                          </div>
                        <% _ -> %>
                          <div class="priority__point__bg">
                            <span class="priority__point__t"></span>
                          </div>
                      <% end %>
                    </td>
                    <td data-label="Date de début" style="min-width: 125px"> <%= Calendar.strftime(task.date_start, "%d-%m-%Y") %> </td>
                    <td data-label="Date d'échéance"> <%= Calendar.strftime(task.deadline, "%d-%m-%Y") %> </td>
                    <td data-label="Progression">
                      <input name="progression_change" type="number" value={task.progression} style="width: 75px; color: #fff;" min="0"
                      max="100"/>
                    </td>
                    <td class="btn-table" style="padding: 0;">
                      <button
                        title="Mettre à jour"
                        type="submit"
                        class="bi bi-arrow-repeat plus__icon table-button"
                        style="border-radius: 50%;"
                      />
                    </td>
                    <td data-label="Actions" class="d-action">
                      <div  style="display: inline-block">
                        <input
                          title="Mettre à jour"
                          value="Mettre à jour"
                          type="submit"
                          class="table-button btn-mobile"
                        />
                        <div
                          title="Afficher"
                          class="table-button btn-mobile"
                          phx-click="show_plus_modal"
                          phx-value-id={task.card}
                          style="margin-top: -40px; background-color: #27ae60; border-color: #27ae60;"
                        >
                          Afficher
                        </div>
                      </div>
                    </td>
                </form>
                  <td class="btn-table">
                    <button
                      title="Afficher"
                      class="bi bi-plus-circle plus__icon table-button"
                      phx-click="show_plus_modal"
                      phx-value-id={task.card}
                      style="background-color: #27ae60; border-color: #2ecc71; border-radius: 50%;"
                    />
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end
end
