defmodule PmLoginWeb.LiveComponent.PlusModalLive do
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
            <div class="modal-card-task">
              <div class="modal-inner-card">
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
                        <a href="#" class="nav-link active bi bi-plus" title="Détails">Détails</a>
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
                        <a class="nav-link bi bi-pencil"
                            title="Modifier"
                            style={"display: #{ if @card.task.hidden, do: "none !important" }; padding: 8px;"}
                            type="button"
                            phx-click="show_modif_menu"
                            phx-value-id={@card.id}
                        >
                        Modifier
                        </a>
                      </li>
                    </ul>
                  </div>

                  <table class="table-tasks-mobile" style="font-size: 11px; margin-bottom: 5px;">
                    <thead>
                      <tr>
                        <th>Nom</th>
                        <th>Attributeur</th>
                        <th>Contributeur</th>
                        <th>Statut</th>
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
                        <td data-label="Nom" style="word-wrap: anywhere;">
                          <%= @card.name %>
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
                        <%= if @card.task.contributor != nil do %>
                          <td data-label="Contributeur">
                            <div style="display: inline-flex;">
                              <img class="profile-pic-mini" style="width: 20px; height: 20px;"
                                  src={Routes.static_path(@socket, "/#{@card.task.contributor.profile_picture}")}/>

                              <div style="margin-top: 2px; margin-left: 5px;">
                                <%= @card.task.contributor.username %>
                              </div>
                            </div>
                          </td>
                        <% end %>
                        <td data-label="Statut"> <%= @card.task.status.title %> </td>
                        <td data-label="Priorité">
                          <%= case @card.task.priority.title do %>
                            <% "Faible" -> %> <div class="low__priority__point__table"> Faible </div>
                            <% "Moyenne" -> %> <div class="avg__priority__point__table"> Moyenne </div>
                            <% "Importante" -> %><div class="high__priority__point__table"> Importante </div>
                            <% "Urgente" -> %><div class="urg__priority__point__table"> Urgente </div>
                            <% _ -> %><div class="priority__point__table"></div>
                          <% end %>
                        </td>
                        <td data-label="Date de début">
                          <%= Utilities.letters_date_format(@card.task.date_start) %>
                        </td>
                        <td data-label="Date de fin">
                          <%= if @card.task.date_end != nil do
                            Utilities.letters_date_format(@card.task.date_end)
                          else
                            "En attente"
                          end %>
                        </td>

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
                        <td data-label="Progression"> <%= @card.task.progression %> % </td>
                        <td data-label="Date d'échéance">
                          <%= Utilities.letters_date_format(@card.task.deadline) %>
                        </td>
                        <%= if @card.task.description == nil or @card.task.description == " " or @card.task.description == [] do %>
                          <td data-label="Description" style="word-wrap: anywhere;">
                              Aucune description
                          </td>
                        <% end %>
                      </tr>
                    </tbody>
                  </table>

                  <%= if @card.task.without_control and @card.task.status_id != 5 do %>
                    <button type="button" class="btn btn-lg btn-success" phx-click="achieve" phx-value-id={@card.task.id}>Achever</button>
                  <% end %>

                  <div class="zoom-out" style="margin-bottom: 6px; font-size: 11px">
                    Nombre approximatif d'heures par jour ouvrable pour l'intervenant pour terminer cette tâche avant la date d'échéance:
                  </div>

                  <p class="column zoom-out task-working-hours" style="margin-bottom: 10px">
                    <%= PmLogin.Monitoring.avg_working_hours(@card.task) %> heures
                  </p>

                  <!--
                  <button class="button button-outline" type="button" phx-click="left-button-click" phx-target={"#modal-#{@id}"}>
                    <div>
                      <%= @left_button %>
                    </div>
                  </button>
                  -->

                  <div class="row">
                    <div class="column column-100">
                      <i style="font-size: 10px;">
                        Créee le <%= Utilities.simple_date_format_with_hours(@card.task.inserted_at) %>
                      </i>
                    </div>
                  </div>

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
