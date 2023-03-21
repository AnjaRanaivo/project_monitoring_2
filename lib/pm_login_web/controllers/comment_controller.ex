defmodule PmLoginWeb.CommentController do
  use PmLoginWeb, :controller

  # alias PmLogin.Monitoring
  # alias PmLogin.Monitoring.Comment

  # def index(conn, _params) do
  #   comments = Monitoring.list_comments()
  #   render(conn, "index.html", comments: comments)
  # end

  # def new(conn, _params) do
  #   changeset = Monitoring.change_comment(%Comment{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{"comment" => comment_params}) do
  #   case Monitoring.create_comment(comment_params) do
  #     {:ok, comment} ->
  #       conn
  #       |> put_flash(:info, "Comment created successfully.")
  #       |> redirect(to: Routes.comment_path(conn, :show, comment))
  #
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   comment = Monitoring.get_comment!(id)
  #   render(conn, "show.html", comment: comment)
  # end

  # def edit(conn, %{"id" => id}) do
  #   comment = Monitoring.get_comment!(id)
  #   changeset = Monitoring.change_comment(comment)
  #   render(conn, "edit.html", comment: comment, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "comment" => comment_params}) do
  #   comment = Monitoring.get_comment!(id)
  #
  #   case Monitoring.update_comment(comment, comment_params) do
  #     {:ok, comment} ->
  #       conn
  #       |> put_flash(:info, "Comment updated successfully.")
  #       |> redirect(to: Routes.comment_path(conn, :show, comment))
  #
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", comment: comment, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   comment = Monitoring.get_comment!(id)
  #   {:ok, _comment} = Monitoring.delete_comment(comment)
  #
  #   conn
  #   |> put_flash(:info, "Comment deleted successfully.")
  #   |> redirect(to: Routes.comment_path(conn, :index))
  # end
  
end
