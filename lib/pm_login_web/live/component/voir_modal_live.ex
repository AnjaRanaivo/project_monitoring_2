defmodule PmLoginWeb.LiveComponent.VoirModalLive do
  use Phoenix.LiveComponent
  # import Phoenix.HTML.Form
  # import PmLoginWeb.ErrorHelpers
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
        <div id="plus_modal_container" class="modal-container-menu" style={"visibility: #{if @show_plus_modal, do: "visible", else: "hidden" }; opacity: #{ if @show_plus_modal, do: "1 !important", else: "0" };"}>
          <%= if not is_nil(@card) do %>
          <div class="modal-inner-container">
            <div class="modal-card-tasks" style="height: auto; width: auto; max-width: 50rem;border-radius: 0.4rem; background-color: #fff;">
              <div class="modal-inner-card">
                <!-- Title -->
                <%= if @title != nil do %>
                <div class="modal-title">
                  <%= @title %>
                  <a href="#" class="x__close" style="position: relative; left: 0; margin-top: -5px;" title="Fermer" phx-click="close" ><i class="bi bi-x"></i></a>
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
                  <table class="table-tasks-mobile" style="font-size: 11px; margin-bottom: 5px;">
                    <thead>
                      <tr>
                        <th>Titre</th>
                        <th>Contributeur</th>
                        <th>Statut</th>
                        <th>Priorité</th>
                        <th>Date de début</th>
                        <th>Date de fin</th>
                        <th>Progression</th>
                        <th>Date de mise à jour</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for task <- @card do %>
                        <tr>
                          <td data-label="Titre" style="word-wrap: anywhere;">
                            <%= task.title %>
                          </td>
                          <%= if task.contributor_id != nil do %>
                            <td data-label="Contributeur">
                                <div style="display: inline-flex;">
                                  <div style="margin-top: 2px; margin-left: 5px;">
                                    <%= PmLogin.Login.list_contributors_users(task.contributor_id).username %>
                                  </div>
                                </div>
                            </td>
                            <% else %>
                            <td data-label="Contributeur">
                                <div style="display: inline-flex;">
                                  <div style="margin-top: 2px; margin-left: 5px;">
                                    <%= PmLogin.Login.list_contributors_users(task.contributor_id).username %>
                                  </div>
                                </div>
                            </td>
                          <% end %>
                          <td data-label="Statut"> <%= PmLogin.Monitoring.list_statuses_by_id(task.status_id).title %> </td>
                          <td data-label="Priorité">
                              <%= case task.priority_id do %>
                                <% 1 -> %> <div class="low__priority__point__table"> Faible </div>
                                <% 2 -> %> <div class="avg__priority__point__table"> Moyenne </div>
                                <% 3 -> %><div class="high__priority__point__table"> Importante </div>
                                <% 4 -> %><div class="urg__priority__point__table"> Urgente </div>
                                <% _ -> %><div class="priority__point__table"></div>
                              <% end %>
                            </td>
                            <td data-label="Date de début">
                              <%= Utilities.letters_date_format(task.date_start) %>
                            </td>
                            <td data-label="Date de fin">
                              <%= if task.date_end != nil do
                                Utilities.letters_date_format(task.date_end)
                              else
                                "En attente"
                              end %>
                            </td>
                            <%
                            estimated_duration = task.estimated_duration / 60
                                               # trunc, retourne la partie entier
                            i_hour             = trunc(estimated_duration)
                            e                  = estimated_duration - i_hour
                            i_minutes          = round(e * 60)

                            performed_duration = task.performed_duration / 60
                                               # trunc, retourne la partie entier
                            hour_p             = trunc(performed_duration)
                            p                  = performed_duration - hour_p
                            minutes_p          = round(p * 60)
                          %>


                        <td data-label="Durée estimée">
                          <%=
                            cond do
                              i_hour == 0 and i_minutes >= 0 -> if i_minutes > 1, do: "#{i_minutes} minutes", else: "#{i_minutes} minute"
                              i_hour >= 0 and i_minutes == 0 -> if i_hour > 1, do: "#{i_hour} heures", else: "#{i_hour} heure"
                              i_hour > 0  and i_minutes > 0  -> "#{i_hour} h #{i_minutes} m"
                              true                           -> ""
                            end
                          %>
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
                            <td data-label="Progression"> <%= task.progression %> % </td>
                            <td data-label="Date d'échéance">
                               <%= Utilities.letters_date_format(task.deadline) %>
                            </td>
                            <%= if task.description == nil or task.description == " " or task.description == [] do %>
                            <td data-label="Description" style="word-wrap: anywhere;">
                                Aucune description
                            </td>
                            <% end %>
                            <td data-label="Date de mise a jour">  <%= Utilities.letters_date_format(task.updated_at) %> </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>

                  <div class="zoom-out" style="margin-bottom: 6px; font-size: 11px">
                    Nombre approximatif d'heures par jour ouvrable pour l'intervenant pour terminer cette tâche avant la date d'échéance:
                  </div>
                  <%= for tasks <- @card do %>
                  <p class="column zoom-out task-working-hours" style="margin-bottom: 10px">
                    <%= PmLogin.Monitoring.avg_working_hours(tasks) %> heures
                  </p>


                  <div class="row">
                    <div class="column column-100">
                      <i style="font-size: 10px;">
                        Créee le <%= Utilities.simple_date_format_with_hours(tasks.inserted_at) %>
                      </i>
                    </div>
                  </div>
                  <% end %>

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
