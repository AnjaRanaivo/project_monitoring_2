# mix test test/controllers/user_controller_test.exs
defmodule PmLoginWeb.UserControllerTest do
  use PmLoginWeb.ConnCase
  import Plug.Conn

  describe "list" do
    test "displays user list for admin user" do
      conn = build_conn()
      conn = Plug.Test.init_session(conn, %{curr_user_id: 57})
      conn = Login.put_session_user(conn, %Login.User{id: 57, right_id: 1})

      conn = get(conn, Routes.user_path(conn, :list))

      assert html_response(conn, 200) =~ "Liste des utilisateurs"
    end

    test "redirects to index page for non-admin user" do
      conn = build_conn()
      conn = Plug.Test.init_session(conn, %{curr_user_id: 53})
      conn = Login.put_session_user(conn, %Login.User{id: 53, right_id: 2})

      conn = get(conn, Routes.user_path(conn, :list))

      assert redirected_to(conn) == Routes.user_path(conn, :index)
      assert get_flash(conn, :error) == "Désolé, vous n'êtes pas administrateur!"
    end

    test "redirects to index page for non-connected user" do
      conn = build_conn()

      conn = get(conn, Routes.user_path(conn, :list))

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_flash(conn, :error) == "Connectez-vous d'abord!"
    end
  end

  describe "authenticate" do
    test "with valid params" do
      user_params = %{username: "Mgbi", email: "admin@admin.mgbi", password: "0000"}

      conn = post(conn(), "/auth", user_params)

      assert conn.status == 200
      assert Repo.get_by(PmLogin.Login.User, email: "admin@admin.mgbi") != nil
    end

    test "with invalid params" do
      user_params = %{name: "Mgbi", email: "admin@admin.mgbi", password: "0001"}

      conn = post(conn(), "/auth", user_params)

      assert conn.status == 422
      assert json_response(conn)["errors"]["email"] == ["is invalid"]
    end
  end
end
