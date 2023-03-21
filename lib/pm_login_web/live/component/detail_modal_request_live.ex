defmodule PmLoginWeb.LiveComponent.DetailModalRequestLive do
  use Phoenix.LiveComponent
  alias PmLogin.Utilities

  @defaults %{
    left_button: "Cancel",
    left_button_action: nil,
    left_button_param: nil,
    right_button: "OK",
    right_button_action: nil,
    right_button_param: nil
  }

  def render(assigns) do
    ~H"""
    <div id={"modal-#{@id}"}>
      <!-- Modal Background -->
      <div
        id="task_modal_container"
        class="modal-container"
        style={
                "
                  visibility: #{ if @show_detail_request_modal, do: "visible", else: "hidden" };
                  opacity: #{ if @show_detail_request_modal, do: "1 !important", else: "0" };
                  overflow: hidden;
                 "
              }
      >
      <%= if not is_nil(@client_request) do %>
        <div class="modal-inner-container" phx-window-keydown="modal_close">
          <div class="modal-card-task" style="min-width: 450px;">
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
                <table class="table-tasks-mobile" style="font-size: 11px; margin-bottom: 5px;">
                  <thead>
                    <tr>
                      <th>Client</th>
                      <th>Titre</th>
                      <th>Description</th>
                      <th>Date d'envoi</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td data-label="Client" style="word-wrap: anywhere;">
                      <%= @client_request.active_client.user.username %>
                      </td>
                      <td data-label="Titre" style="word-wrap: anywhere;">
                        <%= @client_request.title %>
                      </td>
                      <td data-label="Description">
                        <div style="word-wrap: anywhere;">
                          <%= @client_request.content %>
                        </div>
                      </td>
                      <td data-label="Date d'envoi"> <%= Utilities.letters_date_format_with_hours(@client_request.date_post) %> </td>

                      <%= if not Enum.empty?(@client_request.file_urls) do %>
                        <td data-label="Fichiers" style="min-height: 40px;">
                          <div class="" style="display: flex; float: right;">
                              <%= for url <- @client_request.file_urls do %>
                                <%= if Path.extname(url) in [".jpg", ".jpeg", ".png"] do %>
                                  <a href={url} style="font-size: 25px; margin: 0 0 0 15px">
                                    <i class="bi bi-file-earmark-image" title={Path.basename(url)} style="color: #2c3e50"></i>
                                  </a>
                                <% else %>
                                  <a href={url} download style="font-size: 25px; margin: 0 0 0 15px">
                                    <%= cond do %>
                                      <% String.ends_with?(Path.basename(url), ".pdf")   -> %> <i class="bi bi-filetype-pdf" title={Path.basename(url)} style="color: #e13f2d;"></i>
                                      <% String.ends_with?(Path.basename(url), ".txt")   -> %> <i class="bi bi-filetype-txt" title={Path.basename(url)} style="color: #7f8c8d;"></i>
                                      <% String.ends_with?(Path.basename(url), ".odt")   -> %> <i class="bi bi-files" title={Path.basename(url)} style="color: #2c3e50;"></i>
                                      <% String.ends_with?(Path.basename(url), ".ods")   -> %> <i class="bi bi-files" title={Path.basename(url)} style="color: #2c3e50;"></i>
                                      <% String.ends_with?(Path.basename(url), ".odp ")  -> %> <i class="bi bi-files" title={Path.basename(url)} style="color: #2c3e50;"></i>
                                      <% String.ends_with?(Path.basename(url), ".csv")   -> %> <i class="bi bi-filetype-csv" title={Path.basename(url)} style="color: #1da355;"></i>
                                      <% String.ends_with?(Path.basename(url), ".xml")   -> %> <i class="bi bi-filetype-xml" title={Path.basename(url)} style="color: #f39c12;"></i>
                                      <% String.ends_with?(Path.basename(url), ".xls ")  -> %> <i class="bi bi-filetype-xls" title={Path.basename(url)} style="color: #27ae60;"></i>
                                      <% String.ends_with?(Path.basename(url), ".xlsx")  -> %> <i class="bi bi-filetype-xlsx" title={Path.basename(url)} style="color: #27ae60;"></i>
                                      <% String.ends_with?(Path.basename(url), ".ppt")   -> %> <i class="bi bi-filetype-ppt" title={Path.basename(url)} style="color: #e67e22;"></i>
                                      <% String.ends_with?(Path.basename(url), ".pptx ") -> %> <i class="bi bi-filetype-pptx" title={Path.basename(url)} style="color: #e67e22;"></i>
                                      <% String.ends_with?(Path.basename(url), ".doc")   -> %> <i class="bi bi-filetype-doc" title={Path.basename(url)} style="color: #2980b9;"></i>
                                      <% String.ends_with?(Path.basename(url), ".docx")  -> %> <i class="bi bi-filetype-docx" title={Path.basename(url)} style="color: #2980b9;"></i>
                                      <% true -> %>
                                    <% end %>
                                  </a>
                                  <br>
                                <% end %>
                              <% end %>
                            </div>
                          </td>
                        <% end %>

                        <%= if @client_request.content == nil or @client_request.content == " " or @client_request.content == [] do %>
                          <td data-label="Description" style="word-wrap: anywhere;">
                              Aucune description
                          </td>
                        <% end %>
                    </tr>
                  </tbody>
                </table>

                <button
                  class="button button-outline"
                  type="button"
                  phx-click="left-button-click"
                  phx-target={"#modal-#{@id}"}
                  style="margin: 1rem 0 0 0"
                >
                  <div>
                    <%= @left_button %>
                  </div>
                </button>

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
