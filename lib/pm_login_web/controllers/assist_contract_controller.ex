defmodule PmLoginWeb.AssistContractController do
  use PmLoginWeb, :controller
  alias Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Services.AssistContract
  alias PmLogin.Login

  def index(conn, _params) do
    # render(conn, "index.html", assist_contracts: assist_contracts)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          assist_contracts = Services.list_contracts()
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.AssistContractLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "assist_contracts" => assist_contracts}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def new(conn, _params) do
    # render(conn, "new.html", changeset: changeset)

    if Login.is_connected?(conn) do
      cond do
        Login.is_admin?(conn) ->
          changeset = Services.change_assist_contract(%AssistContract{})
          LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewContractLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

        true ->
          conn
            |> Login.not_admin_redirection
      end
    else
      conn
      |> Login.not_connected_redirection
    end
  end

  def create(conn, %{"assist_contract" => assist_contract_params}) do
    case Services.create_assist_contract(assist_contract_params) do
      {:ok, assist_contract} ->
        conn
        |> put_flash(:info, "Contrat d'assistance créé avec succès")
        |> redirect(to: Routes.assist_contract_path(conn, :show, assist_contract))

      {:error, %Ecto.Changeset{} = changeset} ->
        # render(conn, "new.html", changeset: changeset)
        LiveView.Controller.live_render(conn, PmLoginWeb.Services.NewContractLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset}, router: PmLoginWeb.Router)

    end
  end

  def show(conn, %{"id" => id}) do
    assist_contract = Services.get_contract!(id)
    # render(conn, "show.html", assist_contract: assist_contract)
    LiveView.Controller.live_render(conn, PmLoginWeb.Services.ShowContractLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "assist_contract" => assist_contract}, router: PmLoginWeb.Router)

  end

  def edit(conn, %{"id" => id}) do
    assist_contract = Services.get_assist_contract!(id)
    changeset = Services.change_assist_contract(assist_contract)
    # render(conn, "edit.html", assist_contract: assist_contract, changeset: changeset)
    LiveView.Controller.live_render(conn, PmLoginWeb.Services.EditContractLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "assist_contract" => assist_contract, "changeset" => changeset}, router: PmLoginWeb.Router)

  end

  def update(conn, %{"id" => id, "assist_contract" => assist_contract_params}) do
    assist_contract = Services.get_assist_contract!(id)

    case Services.update_assist_contract(assist_contract, assist_contract_params) do
      {:ok, assist_contract} ->
        conn
        |> put_flash(:info, "Contrat d'assistance mis à jour.")
        |> redirect(to: Routes.assist_contract_path(conn, :show, assist_contract))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", assist_contract: assist_contract, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    assist_contract = Services.get_assist_contract!(id)
    {:ok, _assist_contract} = Services.delete_assist_contract(assist_contract)

    conn
    |> put_flash(:info, "Contrat d'assistance supprimé.")
    |> redirect(to: Routes.assist_contract_path(conn, :index))
  end

end
