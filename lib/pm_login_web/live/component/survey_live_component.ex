defmodule PmLoginWeb.LiveComponent.SurveyLiveComponent do
  use Phoenix.LiveComponent

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    PmLoginWeb.ProjectView.render("survey_live_component.html", assigns)
  end
end
