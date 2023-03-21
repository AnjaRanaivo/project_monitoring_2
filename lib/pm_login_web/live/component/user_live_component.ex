defmodule PmLoginWeb.LiveComponent.UserLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("user_live_component.html", assigns)
  end
end
