defmodule PmLoginWeb.LiveComponent.TaskModalLive do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers

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
      <div id="task_modal_container" class="modal-container" style={"visibility: #{ if @show_task_modal, do: "visible", else: "hidden" }; opacity: #{ if @show_task_modal, do: "1 !important", else: "0" };"}>
        <div class="modal-inner-container">
          <div class="modal-card-task">
            <div class="modal-inner-card">
              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title">
                <%= @title %>
                <a href="#" class="x__close" style="position: relative; left: 0; margin-top: -5px" title="Fermer" phx-click="left-button-click" phx-target={"#modal-#{@id}"}><i class="bi bi-x"></i></a>
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
              <.form let={f} for={@task_changeset} phx-submit="save">

                  <div class="column">
                    <label class="zoom-out">Tâche</label>
                    <%= text_input f, :title %>
                    <div class="zoom-out">
                      <%= error_tag f, :title %>
                    </div>
                    <%= hidden_input f, :project_id, value: @pro_id %>
                    <%= hidden_input f, :attributor_id, value: @curr_user_id %>
                  </div>

                  <div class="column">
                    <label class="zoom-out">Description</label>
                    <div class="zoom-out">
                      <input id="task_description" name="task[description]"/>
                      <%= error_tag f, :description %>
                    </div>
                  </div>

                  <div class="column">
                    <label class="zoom-out">Durée estimée</label>
                    <div style="display: flex; font-size: 12px;">
                      <input id="task_estimated_duration_hour" name="task[hour]" type="number" min="0" placeholder="Heure" style="margin-right: 10px" required/>
                      <div style="margin-top: 9px;">
                        h
                      </div>
                      <input id="task_estimated_duration_minutes" name="task[minutes]" type="number" min="0" max="60" placeholder="Minutes" style="margin-right: 10px; margin-left: 10px;" required/>
                      <div style="margin-top: 9px;">
                        m
                      </div>
                    </div>
                    <div class="zoom-out">
                      <%= error_tag f, :estimated_duration %>
                      <%= error_tag f, :negative_estimated %>
                    </div>
                  </div>

                  <div class="row">

                    <div class="column">
                      <label class="zoom-out">Date d'écheance</label>
                      <%= date_input f, :deadline %>
                      <div class="zoom-out">
                        <%= error_tag f, :deadline %>
                        <%= error_tag f, :deadline_lt %>
                        <%= error_tag f, :deadline_before_dtstart %>
                      </div>

                    </div>

                  <%= if not @is_contributor do %>
                    <div class="column">
                      <label class="zoom-out">Assigner intervenant</label>
                      <%= select f, :contributor_id, @attributors ++ @contributors, style: "width: -webkit-fill-available; width: -moz-available; height: 38px;" %>
                      <div class="zoom-out">
                        <%= error_tag f, :contributor_id %>
                      </div>
                    </div>
                  <% end %>
                  </div>

                  <div class="row">
                    <div class="column">

                      <%= radio_button f, :is_major, "true", class: "btn-check", id: "task_danger-outlined", autocomplete: "off" %>
                      <%= label f, "danger-outlined", "TÂCHE MAJEURE", class: "btn btn-danger", style: "font-size: 80%;"%>

                      <%= radio_button f, :is_major, "false", class: "btn-check", id: "task_secondary-outlined", autocomplete: "off" , checked: true%>
                      <%= label f, "secondary-outlined", "Tâche mineure", class: "btn btn-outline-secondary", style: "font-size: 90%;" %>

                    </div>
                  </div>

                  <div class="row">
                    <div class="column">
                      <label class="zoom-out">Sans contrôle</label>
                      <%= checkbox f, :without_control %>
                    </div>
                  </div>

                  <!-- Buttons -->
                  <div class="modal-buttons">
                      <!-- Left Button -->
                      <a
                        href="#" class="button button-outline"
                        type="button"
                        phx-click="left-button-click"
                        phx-target={"#modal-#{@id}"}>
                        <div>
                          <%= @left_button %>
                        </div>
                      </a>

                      <div class="right-button">
                        <%= submit "Créer tâche" %>
                      </div>

                  </div>



                </.form>

              </div>


            </div>
          </div>
        </div>
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
