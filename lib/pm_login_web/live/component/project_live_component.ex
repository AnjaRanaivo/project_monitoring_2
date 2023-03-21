defmodule PmLoginWeb.LiveComponent.ProjectLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("project_live_component.html", assigns)
  end
end
