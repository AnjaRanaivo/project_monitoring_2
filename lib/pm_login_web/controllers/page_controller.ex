defmodule PmLoginWeb.PageController do
  use PmLoginWeb, :controller
  alias PmLogin.Login.User
  alias PmLogin.Login

  def index(conn, _params) do

    case get_session(conn, :curr_user_id) do
      nil ->
        changeset = Login.change_user(%User{})
        render(conn, "index.html", changeset: changeset, layout: {PmLoginWeb.LayoutView, "login_layout.html"})

      _ ->
        conn
        |> redirect(to: Routes.user_path(conn, :index))
    end


  end

end
