defmodule PmLoginWeb.LiveComponent.Loading do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    PmLoginWeb.ProjectView.render("loading.html", assigns)
  end
end
