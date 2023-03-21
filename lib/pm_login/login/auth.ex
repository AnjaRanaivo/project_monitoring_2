defmodule PmLogin.Login.Auth do
  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Repo

  @primary_key false
  schema "auth" do
    field :id, :id
    field :username, :string
    field :profile_picture, :string
    field :email, :string
    field :right_id, :id
    field :title, :string
  end

end
