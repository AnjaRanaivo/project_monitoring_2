defmodule PmLoginWeb.LiveComponent.CommentsModalLive do
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Utilities

  @moduledoc """
  This is a general modal component with title, body text, and two buttons.

  A required action string and optional parameter are provided for each
  button when the modal is initialized. These will be returned to the caller
  when the corresponding button is clicked.

  The caller must have message handlers defined for each button that takes
  the given action and parameter for each button. For example:

      def handle_info(
        {ModalLive, :button_clicked, %{action: "delete", param: item_id}},
        socket
      )

  This is a stateful component, so you MUST specify an id when calling
  live_component.

  The component can be called like:

      <%= live_component(@socket,
                         ModalLive,
                         id: "confirm-boom",
                         title: "Go Boom?",
                         body: "Are you sure you want to crash the counter?",
                         right_button: "OK",
                         right_button_action: "crash",
                         right_button_param: "boom",
                         left_button: "Cancel",
                         left_button_action: "cancel-boom",
                         left_button_param: nil)
      %>
  """
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
      <script>
        var messageBody = document.querySelector('#messageBody');
        messageBody.scrollTop = messageBody.scrollHeight - messageBody.clientHeight
      </script>


      <!-- Modal Background -->
      <div id="comment_modal_container" class="modal-container" style={"visibility: #{ if @show_comments_modal, do: "visible", else: "hidden" }; opacity: #{if @show_comments_modal, do: "1 !important", else: "0" };"}>
        <%= if not is_nil(@card) do %>
          <div class="modal-inner-container">
            <div class="modal-card-comments">

              <!-- MODAL INNER CARD "DONE" START -->
              <div class="modal-inner-card new__inner__card">

                  <!-- Title -->
                  <%= if @title != nil do %>
                    <div class="row modal-title" style="width: auto; display: inline-block;">
                      <%= @title %>
                      <div class="load__icons">
                        <a href="#" style="font-size: 25px;" title="derniers commentaires" phx-click="scroll-bot"><i class="bi bi-arrow-bar-down"></i></a>
                        <a href="#" style="font-size: 25px;" id="clock_comment" title="charger anciennes commentaires" phx-click="load_comments"><i class="bi bi-arrow-clockwise"></i></a>
                        <a href="#" style="font-size: 30px;" title="Fermer" phx-click="left-button-click" phx-target={"#modal-#{@id}"}><i class="bi bi-x"></i></a>
                      </div>
                    </div>
                  <% end %>

                  <!-- Body -->
                  <%= if @body != nil do %>
                    <div class="modal-body">
                      <%= @body %>
                    </div>
                  <% end %>

                  <!-- MODAL BODY "DONE" START-->
                    <div class="modal-body">
                    <% current_user = PmLogin.Login.get_user!(@curr_user_id) %>
                    <% current_username = PmLogin.Login.get_user!(@curr_user_id).username %>
                    <div>
                      <div id="messageBody" class="comments-section" phx-hook="MessageBody">

                          <!-- start of one comment -->
                            <%= for comment <- Enum.reverse(@card.task.comments) do %>
                                <div class="comment__div"
                                     style={"#{
                                              if comment.poster_id == @curr_user_id do
                                                "background-color: #3498db; float: right;"
                                              else
                                                "margin-left: 20px; background-color: #95a5a6; float: left"
                                              end
                                              }"}>

                                <%= if comment.poster_id == @curr_user_id do %>
                                  <!--
                                  <div>
                                    <div style="display: flex;">
                                      <img class="pp__comment" src={Routes.static_path(@socket, "/#{current_user.profile_picture}")} />
                                      <div class="username__comment__you"> <%= current_username %> </div>
                                    </div>
                                  </div>
                                  -->
                                <% else %>
                                  <div>
                                    <div style="display: flex;">
                                      <img class="pp__comment" src={Routes.static_path(@socket, "/#{comment.poster.profile_picture}")} />
                                      <div class="username__comment"><%= comment.poster.username %></div>
                                    </div>
                                  </div>
                                <% end %>

                                <%= if comment.poster_id == @curr_user_id do %>

                                  <div>
                                    <div>
                                        <div style="float: left; word-wrap: anywhere; font-size: 12px; margin-right: 20px; text-align: justify;"><%= comment.content %></div>
                                        <div class="column" style="padding: 0">
                                          <%= for url <- comment.file_urls do %>
                                            <%= if Path.extname(url)==".jpg" or Path.extname(url)==".png" or Path.extname(url)==".jpeg" do %>
                                                <a href={url} style="margin-bottom: 10px;"><img src={url} alt="" height="100"/></a>
                                              <% else %>
                                                <a href={url} download><%= Path.basename(url) %></a>
                                                <br/>
                                            <% end %>
                                          <% end %>
                                        </div>
                                    </div>
                                  </div>

                                <% else %>
                                    <div>
                                      <div>
                                        <div style="float: left; word-wrap: anywhere; font-size: 12px; margin-right: 20px; text-align: justify;"><%= comment.content %></div>
                                        <div class="column" style="padding: 0">
                                          <%= for url <- comment.file_urls do %>
                                            <%= if Path.extname(url)==".jpg" or Path.extname(url)==".png" or Path.extname(url)==".jpeg" do %>
                                              <a href={url} style="margin-bottom: 10px;"><img src={url} alt="" height="100"/></a>
                                              <% else %>
                                              <a href={url} download><%= Path.basename(url) %></a>
                                              <br/>
                                            <% end %>
                                          <% end %>
                                        </div>
                                      </div>
                                    </div>
                                <% end %>

                                  <div style="float: right;">
                                    <%= if @curr_user_id == comment.poster_id do %>
                                      <div class="date__footer" style="font-size: 8px;"><%= Utilities.simple_date_format_with_hours(comment.inserted_at) %></div>
                                    <% else %>
                                      <div class="date__footer" style="font-size: 8px;"><%= Utilities.simple_date_format_with_hours(comment.inserted_at) %></div>
                                    <% end %>
                                  </div>

                                </div>

                            <% end %>
                            <!-- end of one comment -->
                      </div>
                    </div>

                </div>
                <!-- MODAL BODY "DONE" END -->

                <!-- Buttons -->
                <div class="row comment__modal__footer">
                  <!-- Left Button -->
                  <!-- Right Button -->
                    <div class="column column-90 col__com__footer">

                        <div class="file_preview_container">
                          <%= for entry <- @uploads.file.entries do %>
                            <div class="comment__preview">
                              <%= if Path.extname(entry.client_name)==".jpg" or Path.extname(entry.client_name)==".png" or Path.extname(entry.client_name)==".jpeg" do %>
                              <%= live_img_preview entry, height: 50 %>
                              <% else %>
                              <p class="file__name__upload"><%= entry.client_name %></p>
                              <% end %>
                              <progress class="progress__comment" value={entry.progress} max="100"></progress>
                              <a href="#" phx-click="cancel-entry" phx-value-ref={entry.ref}>annuler</a>
                            </div>
                          <% end %>
                        </div>

                        <.form let={f} for={@changeset} phx-submit="send-comment" phx-change="change-comment">
                          <div class="form__wrapper" style="margin-left: -20px;">
                            <div style="margin-right: 15px;">
                              <label title="Joindre fichier" class="upload__ico__label">
                                <%=  live_file_input(@uploads.file, class: "file_inputs") %>
                                <i class="bi bi-upload upload__com__icon"></i>
                              </label>
                              <%= for {_ref, msg} <- @uploads.file.errors do %>
                                <%= if Phoenix.Naming.humanize(msg)=="Too many files" do %>
                                  <p class="alert alert-danger"><%= "Nombre de fichiers max : 5." %></p>
                                <% end %>
                              <% end %>
                            </div>

                            <div>
                              <%= text_input f, :content, size: "20", placeholder: "Message" %>
                              <%= hidden_input f, :poster_id, value: @curr_user_id %>
                              <%= hidden_input f, :task_id, value: @card.task_id %>

                              <button type="submit" class="bt__com__form">
                                <span class="material-icons bt__com__form__ico" style="margin-left: -15px;">send</span>
                              </button>
                            </div>

                          </div>
                          <%= error_tag f, :content %>
                          <!-- <button type="submit" style="background-color: transparent;"><i class="bi bi-symmetry-horizontal" style="font-size: 200%;color: gray;"></i></button> -->
                        </.form>

                    </div>

                </div>

            </div>
              <!-- MODAL INNER CARD "DONE" END -->

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
