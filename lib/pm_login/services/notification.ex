defmodule PmLogin.Services.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias PmLogin.Services.Type

  schema "notifications" do
    field :content, :string
    field :seen, :boolean, default: false
    field :sender_id, :id
    field :receiver_id, :id

    belongs_to :notifications_type, Type

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:content, :seen])
    |> validate_required([:content, :seen])
  end

  def create_changeset(notification, attrs) do
    notification
    |> cast(attrs, [:content, :seen, :sender_id, :receiver_id, :notifications_type_id])
    |> validate_required([:content, :seen, :sender_id, :receiver_id])
    |> put_change(:seen, false)
  end

  def seen_changeset(notification, attrs) do
    notification
    |> cast(attrs, [])
    |> put_change(:seen, true)
  end

  def unseen_changeset(notification, attrs) do
    notification
    |> cast(attrs, [])
    |> put_change(:seen, false)
  end
end
