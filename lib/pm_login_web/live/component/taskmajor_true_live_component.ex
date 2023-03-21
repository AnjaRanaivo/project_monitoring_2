defmodule PmLoginWeb.LiveComponent.TaskmajorTrueLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("ismajor_true_live_component.html", assigns)
  end
end
