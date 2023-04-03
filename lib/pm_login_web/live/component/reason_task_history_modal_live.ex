defmodule PmLoginWeb.LiveComponent.ReasonTaskHistoryModalLive do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Utilities

  @defaults %{
    left_button: nil,
    left_button_action: nil,
    left_button_param: nil,
    right_button: "OK",
    right_button_action: nil,
    right_button_param: nil
  }

  # render modal
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id={"modal-#{@id}"}>
      <!-- Modal Background -->
      <div id="modif_modal_container" class="modal-container" style={"visibility: #{ if @show_reason_task_history_modal, do: "visible", else: "hidden" }; opacity: #{ if @show_reason_task_history_modal, do: "1 !important", else: "0" };"}>
        <%= if not is_nil(@task_history) do %>
        <div class="modal-inner-container">
          <div class="modal-card-task">
            <div class="modal-inner-card" style="width: 450px">
              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title">
                <%= @title %>
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

              <form phx-submit="confirm_reason" style="margin: 0" novalidate>
                 <table class="table-tasks-mobile" style="font-size: 11px;">
                    <tbody>
                      <tr><p style="color: #727272;"><%= @task_history.task.title %></p></tr>
                      <tr>
                        <td data-label="Motif">
                          <input required type="text" id="task_history_reason" name="reason" style="width: 300px; margin-bottom: 0;" placeholder="Motif"/>
                        </td>
                      </tr>
                    </tbody>
                  </table>

                      <div class="modal-buttons" style="margin-top: -15px; margin-bottom: -15px;">
                        <div class="">
                          <%= submit "Valider", class: "button right-button" %>
                        </div>
                      </div>

              </form>
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
