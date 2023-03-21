defmodule PmLoginWeb.LiveComponent.CompletedActivitiesLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("completed_activities_live_component.html", assigns)
  end
end
