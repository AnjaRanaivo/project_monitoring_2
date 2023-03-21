defmodule PmLoginWeb.LiveComponent.SidebarLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("sidebar_live_component.html", assigns)
  end
end
