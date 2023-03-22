defmodule PmLoginWeb.ActiveClient2Controller do
  use PmLoginWeb, :controller

  alias PmLogin.Services
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Login

  alias Phoenix.LiveView


  def index(conn, _params) do
    render(conn,"active_client_2_index.html")

  end








end
