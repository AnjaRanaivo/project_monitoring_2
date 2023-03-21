defmodule PmLoginWeb.LiveComponent.SidebarFalseLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("sidebar_false_live_component.html", assigns)
  end
end
