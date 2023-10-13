defmodule PmLogin.Login do
  use PmLoginWeb, :controller
  @moduledoc """
  The Login context.
  """
  import Plug.Conn
  import Ecto.Query, warn: false
  alias PmLogin.Repo
  alias PmLogin.Services.ActiveClient
  alias PmLogin.Services
  alias PmLogin.Login.{Right, User}
  alias PmLogin.Login.ContributorFunction, as: Function

  @topic inspect(__MODULE__)
  def subscribe do
    Phoenix.PubSub.subscribe(PmLogin.PubSub, @topic)
  end

  defp broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(PmLogin.PubSub, @topic, {__MODULE__, event, result})
  end

  # CONTRIBUTOR FUNCTION

  def list_functions do
    Repo.all(Function)
  end

  def get_function!(id), do: Repo.get!(Function, id)

  def create_function(attrs \\ %{}) do
    %Function{}
    |> Function.create_changeset(attrs)
    |> Repo.insert()
  end

  # SEARCH FUNCTION

  def filter_username(text, username) do
    Regex.match?(~r/^#{text}/i, username)
  end

  # Récuperer la liste des administrateurs
  def list_admins_users do
    query =
      from u in User,
      where: u.right_id == 1

    Repo.all(query)
  end

   # Récuperer la liste des attributeurs
  def list_attributors_users do
    query =
      from u in User,
      where: u.right_id == 2

    Repo.all(query)
  end

  def list_ids_from_attributors_users do
    query = from u in User,
            where: u.right_id == 2,
            select: {u.id}

    Repo.all((query))
  end

  def list_attributor_and_contributor_users do
    query =
      from u in User,
      where: u.right_id in [2, 3],
      select: {u.username, u.id}

    Repo.all(query)
  end

   # Récuperer la liste des attributeurs par son identifiant
  def list_attributors_users(attributor_id) do
    query =
      from u in User,
      where: u.id == ^attributor_id

    # Récupérer qu'une seule résultat
    Repo.one(query)
  end

   # Récuperer la liste des contributeurs
  def list_contributors_users do
    query =
      from u in User,
      where: u.right_id == 3

    Repo.all(query)
  end

  def list_contributors_users_by_username do
    query =
      from u in User,
      where: u.right_id == 3 or u.right_id == 2,
      select: {u.username, u.id}

    Repo.all(query)
  end

    # Récuperer la liste des contributeurs par son identifiant
  def list_contributors_users(contributor_id) do
    query =
      from u in User,
      where: u.id == ^contributor_id

    # Pour ne pas envoyer le résultat en forme de liste
    Repo.one(query)
  end

   # Récuperer la liste des clients
  def list_clients_users do
    query =
      from u in User,
      where: u.right_id == 4

    Repo.all(query)
  end

  # Récuperer la liste utilisateurs non attribuées
  def list_unattributed_users do
    query =
      from u in User,
      where: u.right_id == 5

    Repo.all(query)
  end

  @doc """
  Returns the list of rights.

  ## Examples

      iex> list_rights()
      [%Right{}, ...]

  """
  def list_rights do
    Repo.all(Right)
  end

  # select * from rights where rights.id != 7;

  def list_asc_rights do
    query = from r in Right, where: r.id != 5, order_by: [asc: :id] , select: r
    #5 = non attribué
    Repo.all(query)
  end

  def list_rights_without_archived do
    query = from r in Right, where: r.id != 100, select: r
    #0 = archivé
    Repo.all(query)
  end

  @doc """
  Gets a single right.

  Raises `Ecto.NoResultsError` if the Right does not exist.

  ## Examples

      iex> get_right!(123)
      %Right{}

      iex> get_right!(456)
      ** (Ecto.NoResultsError)

  """
  def get_right!(id), do: Repo.get!(Right, id)

  @doc """
  Creates a right.

  ## Examples

      iex> create_right(%{field: value})
      {:ok, %Right{}}

      iex> create_right(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_right(attrs \\ %{}) do
    %Right{}
    |> Right.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a right.

  ## Examples

      iex> update_right(right, %{field: new_value})
      {:ok, %Right{}}

      iex> update_right(right, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_right(%Right{} = right, attrs) do
    right
    |> Right.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a right.

  ## Examples

      iex> delete_right(right)
      {:ok, %Right{}}

      iex> delete_right(right)
      {:error, %Ecto.Changeset{}}

  """
  def delete_right(%Right{} = right) do
    right
    |> Repo.delete
    |> broadcast_change([:right, :deleted])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking right changes.

  ## Examples

      iex> change_right(right)
      %Ecto.Changeset{data: %Right{}}

  """
  def change_right(%Right{} = right, attrs \\ %{}) do
    Right.changeset(right, attrs)
  end

  alias PmLogin.Login.User
  @doc """
  checks user status functions
  """

  def check_and_redirect(conn, action) do

    if is_connected?(conn) do
      cond do
        is_admin?(conn) ->
            action
        true ->
          conn
            |> not_admin_redirection
      end
    else
      conn
      |> not_connected_redirection
    end

  end

  def do_action(action) do
    action
  end

  def not_contributor_redirection(conn) do
    conn
    |> put_flash(:error, "Désolé, vous n'êtes pas contributeur de Mgbi!")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def not_attributor_redirection(conn) do
    conn
    |> put_flash(:error, "Désolé, vous n'êtes pas attributeur de MGBI!")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def not_admin_redirection(conn) do
    conn
    |> put_flash(:error, "Désolé, vous n'êtes pas administrateur!")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def not_active_client_redirection(conn) do
    conn
    |> put_flash(:error, "Désolé, vous n'êtes pas un client actif!")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def not_connected_redirection(conn) do
    conn
    |> put_flash(:error, "Connectez-vous d'abord!")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def is_connected?(conn) do
    get_curr_user_id(conn) != nil
  end

  def get_curr_user(conn) do
    user = get_curr_user_id(conn) |> get_user!
  end

  def get_curr_user_id(conn) do
    current_id = get_session(conn, :curr_user_id)
  end

  def is_admin?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 1
  end

  def is_unattributed?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 5
  end

  def is_attributor?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 2
  end

  def is_contributor?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 3
  end

  def is_client?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 4
  end

  def is_client_by_user_id?(user_id) do
    user = get_user!(user_id)
    user.right_id == 4
  end

  def is_id_active_client?(id) do
    active_clients = Services.list_active_clients
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    id in ac_ids
  end

  def is_active_client?(conn) do
    user_id = get_curr_user_id(conn)

    active_clients = Services.list_active_clients
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client?(conn) and (user_id in ac_ids)
  end

  def is_not_attributed?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 5
  end

  def is_archived?(conn) do
    user_id = get_curr_user_id(conn)
    user = get_user!(user_id)
    user.right_id == 100
  end


  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def restore_user(%User{} = user) do
    params = %{"right_id" => 5}
    user
    |> User.restore_changeset(params)
    |> Repo.update()
  end

  def archive_user(%User{} = user) do
    params = %{"right_id" => 100}
    user
    |> User.archive_changeset(params)
    |> Repo.update()
    |> broadcast_change([:user, :updated])
  end

  def list_admins_and_attributors(current_user_id) do
    query = from u in User,
            where: u.right_id == 1 or u.right_id == 2

    Repo.all(query)
    |> Enum.map(fn x -> x.id end)
    |> Enum.filter(&(&1!=current_user_id))
  end

  def list_admins(current_user_id) do
    query = from u in User,
            where: u.right_id == 1

    Repo.all(query)
    |> Enum.map(fn x -> x.id end)
    |> Enum.filter(&(&1!=current_user_id))
  end

  def list_attributors do
    attrib_query = from u in User,
                   where: u.right_id == 2
    Repo.all(attrib_query)
  end

  def list_contributors do
    contrib_query = from u in User,
                    where: u.right_id == 3
    Repo.all(contrib_query)
  end

  def list_users do
    Repo.all(User)
  end

  def list_clients do
    clients_query = from u in User,
    where: u.right_id == 4

    ac_ids_query = from ac in ActiveClient, select: ac.user_id

    query = from u in subquery(clients_query), where: u.id in subquery(ac_ids_query)
    Repo.all(query)
  end

  def list_non_active_clients do
    clients_query = from u in User,
                    where: u.right_id == 4

    ac_ids_query = from ac in ActiveClient, select: ac.user_id

    query = from u in subquery(clients_query), where: u.id not in subquery(ac_ids_query)
    Repo.all(query)
  end
  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def clean_record_from_user(%User{} = user) do
    user
    |> User.put_record_changeset(%{"current_record_id" => nil})
    |>Repo.update
  end

  def get_user_with_function_and_current_record!(id) do
    query = from u in User,
      preload: [:function, :current_record],
      where: u.id == ^id

    Repo.one(query)
  end

  def get_profile_picture(id) do
    user = get_user!(id)
    profile_picture = user.profile_picture
  end

  def get_username(id) do
    user = get_user!(id)
    username = user.username
  end
  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_from_project(attrs \\ %{}) do
    %User{}
    |> User.from_project_changeset(attrs)
    |> Repo.insert()
  end

  def broadcast_user_creation(tuple) do
    broadcast_change(tuple, [:user, :created])
  end



  def log_user(attrs \\ %{}) do
    %User{}
    |> User.authenticate(attrs)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def put_new_current_record_to_user(%User{} = user, attrs) do
    user
    |> User.put_record_changeset(attrs)
    |> Repo.update()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.right_changeset(attrs)
    |> Repo.update()
  end

  def update_raw_user_password(%User{} = user, attrs) do
    user
    |> User.update_raw_password(attrs)
    |> Repo.update()
  end

  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def update_password(%User{} = user, attrs) do
    user
    |> User.update_password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  alias PmLogin.Login.Auth

  def asc_username do
    auth = list_asc_auth()
    Enum.sort_by(auth, &(&1.username), :desc)
    # Enum.sort(auth)
  end

  def filter_auth(right_id) do
    case right_id do
      1 -> list_only_auth_admin()
      2 -> list_only_auth_attributor()
      3 -> list_only_auth_contributor()
      4 -> list_only_auth_client()
      5 -> list_only_auth_unattributed()
      100 -> list_only_auth_archived()
      9000 -> list_asc_auth()
    end
  end

  def list_only_auth_admin do
    query = from a in Auth, where: a.right_id == 1,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_only_auth_attributor do
    query = from a in Auth, where: a.right_id == 2,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_only_auth_contributor do
    query = from a in Auth, where: a.right_id == 3,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_only_auth_client do
    query = from a in Auth, where: a.right_id == 4,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_only_auth_unattributed do
    query = from a in Auth, where: a.right_id == 5,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_only_auth_archived do
    query = from a in Auth, where: a.right_id == 100,order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def sort_auth(sort_type) when sort_type == "asc", do: list_asc_username_auth()
  def sort_auth(sort_type) when sort_type == "desc", do: list_desc_username_auth()

  def list_asc_username_auth do
    query = from a in Auth, order_by: [asc: :username], select: a
    Repo.all(query)
  end

  def list_desc_username_auth do
    query = from a in Auth, order_by: [desc: :username], select: a
    Repo.all(query)
  end

  def list_asc_auth do
    query = from a in Auth, order_by: [asc: :right_id], select: a
    Repo.all(query)
  end

  def list_all_auth do
    Repo.all(Auth)
  end

  def get_auth!(id), do: Repo.get_by(Auth, id: "#{id}")

  def is_active_client_admin?(conn) do
    user_id = get_curr_user_id(conn)

    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client?(conn) and (user_id in ac_ids) and (active_client.rights_clients_id == 1)
  end

  def is_active_client_admin_by_user_id?(user_id) do
    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client_by_user_id?(user_id) and (user_id in ac_ids) and (active_client.rights_clients_id == 1)
  end

  def is_active_client_demandeur?(conn) do
    user_id = get_curr_user_id(conn)

    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client?(conn) and (user_id in ac_ids) and (active_client.rights_clients_id == 2)
  end

  def is_active_client_demandeur_by_user_id?(user_id) do
    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client_by_user_id?(user_id) and (user_id in ac_ids) and (active_client.rights_clients_id == 2)
  end

  def is_active_client_utilisateur?(conn) do
    user_id = get_curr_user_id(conn)

    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client?(conn) and (user_id in ac_ids) and (active_client.rights_clients_id == 3)
  end

  def is_active_client_utilisateur_by_user_id?(user_id) do
    active_clients = Services.list_active_clients
    active_client = Services.get_active_client_from_userid!(user_id)
    ac_ids = active_clients |> Enum.map(fn x -> x.user_id end)
    is_client_by_user_id?(user_id) and (user_id in ac_ids) and (active_client.rights_clients_id == 3)
  end

end
