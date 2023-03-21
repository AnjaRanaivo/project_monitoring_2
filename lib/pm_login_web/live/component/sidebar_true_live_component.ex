defmodule PmLoginWeb.LiveComponent.SidebarTrueLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("sidebar_true_live_component.html", assigns)
  end
end
