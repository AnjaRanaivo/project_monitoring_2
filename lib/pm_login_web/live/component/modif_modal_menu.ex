defmodule PmLoginWeb.LiveComponent.ModifModalMenu do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Utilities

  @defaults %{
    left_button: "Cancel",
    left_button_action: nil,
    left_button_param: nil,
    right_button: "OK",
    right_button_action: nil,
    right_button_param: nil
  }

  # render modal
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id={"modal-#{@id}"}>
      <!-- Modal Background -->
      <div
        id="modif_modal_container"
        class="modal-container-menu"
        style={"visibility: #{ if @show_modif_menu, do: "visible", else: "hidden" }; opacity: #{ if @show_modif_menu, do: "1 !important", else: "0" };"}>
        <%= if not is_nil(@card) do %>
        <div class="modal-inner-container">
          <div class="modal-card-task">
            <div class="modal-inner-card" style="width: 450px">
              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title">
                <%= @title %>
                <a href="#" class="x__close" style="position: relative; left: 0; margin-top: -5px;" title="Fermer" phx-click="left-button-click" phx-target={"#modal-#{@id}"}><i class="bi bi-x"></i></a>
              </div>
              <% end %>

              <!-- Body -->
              <%= if @body != nil do %>
              <div class="modal-body">
                <%= @body %>
              </div>
              <% end %>

              <!-- MY FORM -->
              <div class="modal-body">

                <div style="display: flex;">
                  <ul class="navbar nav-tabs">
                    <li class="nav-item">
                      <a title="Afficher" style={"display: #{ if @card.task.hidden, do: "none !important" };"}
                         class="nav-link bi bi-plus" phx-click="show_plus_modal" phx-value-id={@card.id}>
                      Détails
                      </a>
                    </li>
                    <li class="nav-item">
                      <a class="nav-link bi bi-chat-dots"
                          title="Commenter"
                          style={"display: #{ if @card.task.hidden, do: "none !important" }; padding: 8px;"}
                          phx-click="show_comments_menu"
                          phx-value-id={@card.id}
                      >
                      Commenter
                      </a>
                    </li>
                    <li class="nav-item">
                      <a class="nav-link active bi bi-pencil" title="Modifier">
                        Modifier
                      </a>
                    </li>
                  </ul>
                </div>

              <.form let={f} for={@modif_changeset} phx-submit="update_task" style="margin: 0" novalidate>
                <%= hidden_input f, :task_id,value: @card.task.id %>
                 <table class="table-tasks-mobile" style="font-size: 11px;">
                    <thead>
                      <tr>
                        <th>Nom</th>
                        <th>Attributeur</th>
                        <th>Contributeur</th>
                        <th>Priorité</th>
                        <th>Date de début</th>
                        <th>Date de fin</th>
                        <th>Durée estimée</th>
                        <th>Progression</th>
                        <th>Date d'échéance</th>
                        <th>Description</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td data-label="Nom">
                          <input id="task_title" name="task[title]" type="text" value={@card.name} style="width: 300px; margin-bottom: 0;" placeholder="Nom de la tâche"/>
                          <!-- <%= text_input f, :title, [value: @card.name] %> -->
                          <%= error_tag_modif f, :title %>
                        </td>
                        <td data-label="Description">
                          <input id="task_description" name="task[description]" value={@card.task.description} style="width: 300px; margin-bottom: 0;" placeholder="Description"/>
                          <%= error_tag_modif f, :description %>
                        </td>
                        <td data-label="Attributeur">
                          <div style="display: inline-flex;">
                            <img class="profile-pic-mini" style="width: 20px; height: 20px;"
                                src={Routes.static_path(@socket, "/#{@card.task.attributor.profile_picture}")}/>

                            <div style="margin-top: 2px; margin-left: 5px;">
                              <%= @card.task.attributor.username %>
                            </div>
                          </div>
                        </td>
                        <td data-label="Contributeur">
                          <%= if @is_admin or @is_attributor do %>
                            <%= select f, :contributor_id, @attributors ++ @contributors, selected: @card.task.contributor_id, style: "width: 200px; margin-bottom: 0;" %>
                            <%= error_tag_modif f, :contributor_id %>
                          <% else %>
                            <%= if !is_nil(@card.task.contributor_id) do %>
                              <%= @card.task.contributor.username %>
                            <% else %>
                              <div class="zoom-out"> <%= "Pas d'intervenant" %> </div>
                            <% end %>
                          <% end %>
                        </td>
                        <td data-label="Priorité">
                          <%= if @is_contributor and is_nil(@card.task.parent_id) do %>
                            <%= @card.task.priority.title %>
                          <% else %>
                            <%= select f, :priority_id, @priorities, value: @card.task.priority_id, style: "width: 150px; margin-bottom: 0;" %>
                          <% end %>
                        </td>
                        <td data-label="Date de début">
                          <%= if (@is_admin or @is_attributor)do %>
                            <%= date_input f, :date_start, value: @card.task.date_start, style: "width: 150px; margin-bottom: 0;"%>
                          <% else %>
                            <%= Utilities.letters_date_format(@card.task.date_start) %>
                          <% end %>
                        </td>
                        <td data-label="Date d'échéance">
                        <%= if (@is_admin or @is_attributor) do %>
                          <%= date_input f, :deadline, value: @card.task.deadline, style: "width: 150px; margin-bottom: 0;" %>

                          <%= error_tag_modif f, :deadline %>
                          <%= error_tag_modif f, :deadline_lt %>
                          <%= error_tag_modif f, :deadline_before_dtstart %>
                        <% else %>
                          <%= Utilities.letters_date_format(@card.task.deadline) %>
                        <% end %>
                      </td>
                        <td data-label="Date de fin">
                          <%= if @is_contributor and @card.task.status_id == 4 do %>
                            <%= date_input f, :date_end, value: @card.task.date_end, style: "width: 150px; margin-bottom: 0;" %>
                            <%= error_tag_modif f, :dt_end_lt_start %>
                          <% else %>
                              <%= if !is_nil(@card.task.date_end) do %>
                                <%= Utilities.letters_date_format(@card.task.date_end) %>
                              <% else %>
                                En attente
                              <% end %>
                          <% end %>
                        </td>
                        <td data-label="Durée estimée">
                            <%
                              estimated_duration = @card.task.estimated_duration / 60
                                                 # trunc, retourne la partie entier
                              i_hour             = trunc(estimated_duration)
                              e                  = estimated_duration - i_hour
                              i_minutes          = round(e * 60)

                              performed_duration = @card.task.performed_duration / 60
                                                 # trunc, retourne la partie entier
                              hour_p             = trunc(performed_duration)
                              p                  = performed_duration - hour_p
                              minutes_p          = round(p * 60)
                            %>

                          <%= if @is_admin or @is_attributor do %>
                            <input id="task_estimated_duration_hour_performed" name="task[hour_performed]" type="hidden" min="0" placeholder="Heure" value={hour_p} style="max-width: 125px; margin-bottom: 0; height: auto;" required>

                            <input id="task_estimated_duration_minutes_performed" name="task[minutes_performed]" type="hidden" min="0" max="60" placeholder="Minutes" value={minutes_p} style="max-width: 125px; margin-bottom: 0; height: auto;" required>

                            <input id="task_estimated_duration_hour" name="task[hour]" type="number" min="0" placeholder="Heure" value={i_hour} style="max-width: 125px; margin-bottom: 0; height: auto;" required/> h

                            <input id="task_estimated_duration_minutes" name="task[minutes]" type="number" min="0" max="60" placeholder="Minutes" value={i_minutes} style="max-width: 125px; margin-bottom: 0; height: auto;"required/> m
                            <%= error_tag_modif f, :negative_estimated %>
                          <% else %>
                            <%=
                              cond do
                                i_hour == 0 and i_minutes >= 0 -> if i_minutes > 1, do: "#{i_minutes} minutes", else: "#{i_minutes} minute"
                                i_hour >= 0 and i_minutes == 0 -> if i_hour > 1, do: "#{i_hour} heures", else: "#{i_hour} heure"
                                i_hour > 0  and i_minutes > 0  -> "#{i_hour} h #{i_minutes} m"
                                true                           -> ""
                              end
                            %>
                          <% end %>
                        </td>
                        <td data-label="Durée effectuée">
                          <%=
                            cond do
                              hour_p == 0 and minutes_p >= 0 -> if minutes_p > 1, do: "#{minutes_p} minutes", else: "#{minutes_p} minute"
                              hour_p >= 0 and minutes_p == 0 -> if hour_p > 1, do: "#{hour_p} heures", else: "#{hour_p} heure"
                              hour_p > 0  and minutes_p > 0  -> "#{hour_p} h #{minutes_p} m"
                              true                           -> ""
                            end
                          %>
                        </td>
                        <td data-label="Progression">
                          <input id="task_progression" name="task[progression]" style="width: 70px; margin-bottom: 0;" type="number" value={@card.task.progression} min="0" max="100"> %

                          <%= error_tag_modif f, :invalid_progression %>
                          <%= error_tag_modif f, :progression_not_int %>
                        </td>
                      </tr>
                    </tbody>
                  </table>

                      <div class="modal-buttons" style="margin-top: -15px; margin-bottom: -15px;">
                        <!-- Left Button -->
                        <button class="button button-outline"
                                type="button"
                                phx-click="left-button-click"
                                phx-target={"#modal-#{@id}"}>
                          <div>
                            <%= @left_button %>
                          </div>
                        </button>
                          <div class="">
                            <%= submit "Valider", class: "button right-button" %>
                          </div>
                      </div>
              </.form>
              </div>


            </div>
          </div>
        </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{id: _id} = assigns, socket) do
    {:ok, assign(socket, Map.merge(@defaults, assigns))}
  end

  # Fired when user clicks right button on modal
  def handle_event(
        "right-button-click",
        _params,
        %{
          assigns: %{
            right_button_action: right_button_action,
            right_button_param: right_button_param
          }
        } = socket
      ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: right_button_action, param: right_button_param}}
    )

    {:noreply, socket}
  end

  def handle_event(
        "left-button-click",
        _params,
        %{
          assigns: %{
            left_button_action: left_button_action,
            left_button_param: left_button_param
          }
        } = socket
      ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: left_button_action, param: left_button_param}}
    )

    {:noreply, socket}
  end
end
