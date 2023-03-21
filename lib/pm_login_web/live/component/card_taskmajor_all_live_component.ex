defmodule PmLoginWeb.LiveComponent.CardTaskmajorAllLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    PmLoginWeb.ProjectView.render("cardmajor_all_live_component.html", assigns)
  end
end
