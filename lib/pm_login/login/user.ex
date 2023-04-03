defmodule PmLogin.Login.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Login.User
  alias PmLogin.Login
  alias Plug.Upload
  alias PmLoginWeb.Router.Helpers, as: Routes
  alias PmLogin.Login.ContributorFunction
  alias PmLogin.Monitoring.TaskRecord

  schema "users" do
    field :email, :string
    field :password, :string
    field :profile_picture, :string
    field :username, :string
    field :right_id, :id
    # field :current_record_id, :id
    # field :function_id, :id
    belongs_to :current_record, TaskRecord
    belongs_to :function, ContributorFunction
    timestamps()
  end


  # def changeset(user, attrs) do
  #   user
  #   |> cast(attrs, [:username, :email, :password])
  #   |> validate_required([:username, :email, :password])
  #   |> unique_constraint(:username)
  #   |> unique_constraint(:email)
  # end
  #
  @doc false
  def get_right!(right_id) do
    Login.get_right!(right_id)
  end

  def restore_changeset(user, attrs) do
    user
    |> cast(attrs, [:right_id])
  end

  def archive_changeset(user, attrs) do
    user
    |> cast(attrs, [:right_id])
  end

  def authenticate(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required(:username, message: "Nom d'utilisateur ne doit pas être vide")
    |> validate_required(:password, message: "Mot de passe ne peut pas être vide")
    |> check_if_user
    |> check_password
    |> apply_action(:login)
  end

  defp check_if_user(changeset) do
    username = get_field(changeset, :username)
    list = Login.list_users
    usernames = Enum.map(list, fn %User{} = user -> user.username end )
    emails = Enum.map(list, fn %User{} = user -> user.email end )
    # is_user = Enum.member?(usernames, username)

    # if Enum.member?(usernames, username) or Enum.member?(emails, username) do
    #
    # end

    cond do
      Enum.member?(usernames, username) -> changeset
      Enum.member?(emails, username) -> changeset
      true -> add_error(changeset, :not_user, "Identifiant inexistant")
    end

    # if username != nil do
    #     case is_user do
    #       false -> add_error(changeset, :not_user, "Ce nom d'utlisateur n'existe pas")
    #       _ -> changeset
    #     end
    #   else
    #     changeset
    # end


  end

  defp is_user?(string) do
    list = Login.list_users
    usernames = Enum.map(list, fn %User{} = user -> user.username end )
    Enum.member?(usernames, string)
  end

  defp is_email?(string) do
    list = Login.list_users
    emails = Enum.map(list, fn %User{} = user -> user.email end )
    Enum.member?(emails, string)
  end


  defp check_password(changeset) do
    user_name = get_field(changeset, :username)
    pwd = get_field(changeset, :password)
    list = Login.list_users

    user = cond do
      is_user?(user_name) -> Enum.find(list, fn %User{} = u -> u.username === user_name end )
      is_email?(user_name) -> Enum.find(list, fn %User{} = u -> u.email === user_name end )
      true -> add_error(changeset, :not_user, "Identifiant inexistant")
    end

      if user != nil and pwd != nil and (is_user?(user_name) or is_email?(user_name)) do
        str_pwd = to_string(pwd)
        checked = Pbkdf2.verify_pass(str_pwd, user.password)
          case checked do
            false -> add_error(changeset, :wrong_pass, "Mot de passe incorrect")
            _ -> changeset
          end
        else
          changeset
      end

    end


  def update_password_changeset(user, attrs) do
    IO.inspect attrs
    IO.inspect user.id
    user
    |> cast(attrs, [])
    |> required_old_password(attrs)
    |> validate_old_password(user, attrs)
    |> required_new_password(attrs)
    |> put_change(:password, Pbkdf2.hash_pwd_salt(attrs["new_password"]))
  end

  def update_raw_password(user, attrs) do
    user
    |> cast(attrs, [])
    |> required_new_password(attrs)
    |> put_change(:password, Pbkdf2.hash_pwd_salt(attrs["new_password"]))
  end

  def required_old_password(changeset, attrs) do
    case attrs["old_password"] do
      "" -> changeset |> add_error(:old_password, "Entrez votre ancien mot de passe.")
      _ -> changeset
    end
  end

  def validate_old_password(changeset, user, attrs) do
      case Pbkdf2.verify_pass(attrs["old_password"], user.password) do
        false -> add_error(changeset, :old_password, "Ne correspond pas à l'ancien mot de passe")
        _ -> changeset
      end
  end

  def required_new_password(changeset, attrs) do
    case attrs["new_password"] do
      "" -> changeset |> add_error(:new_password, "Entrez nouveau mot de passe.")
      _ -> changeset
    end
  end


  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> validate_required(:username, message: "Nom d'utilisateur ne peut pas être vide")
    |> validate_required(:email, message: "Adresse éléctronique ne peut pas être vide")
    |> unique_constraint(:username, message: "Nom d'utilisateur déjà pris")
    |> validate_format(:email, ~r<(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])>, message: "Format d'email non valide")
    |> unique_constraint(:email, message: "Adresse email déjà pris")
    |> upload_profile_pic(attrs)
  end

  def upload_profile_pic(changeset, attrs) do
      upload = attrs["photo"]
      case upload do
        nil -> changeset

        _ ->
        extension = Path.extname(upload.filename)
        username = get_field(changeset, :username)
        profile_pic_path = "profiles/#{username}-profile#{extension}"
        path_in_db = "images/#{profile_pic_path}"
        File.cp(upload.path, "assets/static/images/#{profile_pic_path}")

        put_change(changeset, :profile_picture, path_in_db )
      end
  end

  def right_changeset(user, attrs) do
    user
    |> cast(attrs, [:right_id, :function_id])
  end

  def from_project_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required_username
    |> validate_required_password
    |> validate_required_email
    |> unique_constraint(:username, message: "Nom d'utilisateur déjà pris")
    |> validate_format(:email, ~r<(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])>, message: "Format d'email non valide")
    |> unique_constraint(:email, message: "Adresse e-mail déjà utilisée")
    |> validate_confirmation(:email, message: "Ne correspond pas à l'adresse mail donnée")
    |> validate_confirmation(:password, message: "Les mots de passe ne correspondent pas")
    |> crypt_pass
    |> put_change(:right_id, 4)
    |> put_default_profile_picture
  end

  def put_record_changeset(user, attrs) do
    user
    |> cast(attrs, [:current_record_id])
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :function_id, :current_record_id])
    |> validate_required_username
    |> validate_required_password
    |> validate_required_email
    |> unique_constraint(:username, message: "Nom d'utilisateur déjà pris")
    |> validate_format(:email, ~r<(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])>, message: "Format d'email non valide")
    |> unique_constraint(:email, message: "Adresse e-mail déjà utilisée")
    |> validate_confirmation(:email, message: "Ne correspond pas à l'adresse mail donnée")
    |> validate_confirmation(:password, message: "Les mots de passe ne correspondent pas")
    |> crypt_pass
    |> put_default_right
    |> put_default_profile_picture
    |> put_change(:function_id, nil)
  end

  defp apply_log_action(changeset) do
    apply_action(changeset, :login)
  end

  defp validate_changeset(changeset) do
      is_valid = changeset.valid?
      case is_valid do
        true -> {:ok, changeset.changes}
        false -> {:error, changeset}
      end
  end

  defp put_default_right(changeset) do
      put_change(changeset, :right_id, 5)
  end

  defp put_default_profile_picture(changeset) do
      put_change(changeset, :profile_picture, "images/profiles/default_profile_pic.png")
  end

  defp crypt_pass(changeset) do
    pass_field = get_field(changeset, :password)
    cry = to_string(pass_field)
    encrypted = Pbkdf2.hash_pwd_salt(cry)
    put_change(changeset, :password, encrypted)
  end

  defp validate_required_username(changeset) do
    username = get_field(changeset, :username)
    case username do
      nil -> add_error(changeset, :req_uname_error, "Nom d'utilisateur ne doit pas être vide")
      _ -> changeset
    end
  end

  defp validate_required_email(changeset) do
    email = get_field(changeset, :email)
    case email do
      nil -> add_error(changeset, :req_email_error, "L'adresse e-mail ne peut pas être vide")
      _ -> changeset
    end
  end

  defp validate_required_password(changeset) do
    password = get_field(changeset, :password)
    case password do
      nil -> add_error(changeset, :req_pass_error, "Mot de passe ne peut pas être vide")
      _ -> changeset
    end
  end
end

#   no case clause matching: #Ecto.Changeset<action: nil, changes: %{}, errors: [req_pass_error: {"Mot de passe ne peut pas être vide", []}, req_uname_error: {"Nom d'utilisateur ne doit pas être vide", []}], data: #PmLogin.Login.User<>, valid?: false>
#   no case clause matching: #Ecto.Changeset<action: nil, changes: %{password: "sfdsfdsf", username: "sdfsdf"}, errors: [], data: #PmLogin.Login.User<>, valid?: true>
