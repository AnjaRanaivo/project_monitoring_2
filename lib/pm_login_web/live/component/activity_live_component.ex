defmodule PmLoginWeb.LiveComponent.ActivityLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("activity_live_component.html", assigns)
  end
end
