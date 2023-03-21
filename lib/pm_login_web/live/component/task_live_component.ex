defmodule PmLoginWeb.LiveComponent.TaskLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("task_live_component.html", assigns)
  end
end
