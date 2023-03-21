defmodule PmLoginWeb.LiveComponent.TaskmajorFalseLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("ismajor_false_live_component.html", assigns)
  end
end
