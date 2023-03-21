defmodule PmLogin.Kanban.Position do
  import Ecto.Query
  import Ecto.Changeset

  defmodule ForbiddenPositionError do
    defexception message: "Forbidden position"
  end

  def recompute_positions(changeset, scope_field, position_field \\ :position) do
    prepare_changes(changeset, fn cs ->
      try do
        {old_scope_id, new_scope_id} = get_scope_change(changeset, scope_field)
        {old_position, new_position} = get_position_change(changeset, position_field)

        scope_has_changed = new_scope_id != old_scope_id
        position_has_changed = new_position != old_position
        queryable = cs.data.__struct__
        repo = cs.repo

        if scope_has_changed || position_has_changed do
          new_position =
            correct_new_position(
              new_position,
              queryable,
              repo,
              scope_field,
              new_scope_id,
              scope_has_changed
            )

          remove(cs, scope_field, old_scope_id, position_field, old_position)

          cond do
            is_nil(old_position) ->
              insert(cs, scope_field, new_scope_id, position_field, new_position)
              cs

            is_nil(new_position) ->
              cs

            true ->
              insert(cs, scope_field, new_scope_id, position_field, new_position)
              force_change(cs, position_field, new_position)
          end
        else
          # If position is unchanged there is nothing to do
          # and we return an untouched changeset.
          cs
        end
      rescue
        ForbiddenPositionError -> add_error(cs, :position, "New position is invalid")
      end
    end)
  end

  defp get_scope_change(changeset, scope_field) do
    old_scope_id = Map.get(changeset.data, scope_field)
    new_scope_id = get_change(changeset, scope_field) || old_scope_id
    {old_scope_id, new_scope_id}
  end

  defp get_position_change(changeset, position_field) do
    old_position = Map.get(changeset.data, position_field)
    new_position = get_change(changeset, position_field) || old_position
    {old_position, new_position}
  end

  defp correct_new_position(
         new_position,
         queryable,
         repo,
         scope_field,
         new_scope_id,
         _scope_has_changed
       ) do
    bottom_position = get_bottom_position(queryable, repo, scope_field, new_scope_id)

    cond do
      is_nil(bottom_position) && new_position != 0 -> raise ForbiddenPositionError
      bottom_position && new_position > bottom_position + 1 -> raise ForbiddenPositionError
      new_position < 0 -> raise ForbiddenPositionError
      true -> new_position
    end
  end

  def get_bottom_position(queryable, repo, scope_field, scope_value) do
    queryable
    |> where([s], field(s, ^scope_field) == ^scope_value)
    |> select([q], max(q.position))
    |> repo.one()
  end

  def insert_at_bottom(changeset, scope_field, position_field \\ :position) do
    prepare_changes(changeset, fn cs ->
      queryable = cs.data.__struct__
      repo = cs.repo
      scope_value = get_field(changeset, scope_field)
      current_bottom_position = get_bottom_position(queryable, repo, scope_field, scope_value)

      position =
        if current_bottom_position do
          current_bottom_position + 1
        else
          0
        end

      force_change(cs, position_field, position)
    end)
  end

  defp insert(changeset, scope_field, scope_value, _position_field, new_position) do
    queryable = changeset.data.__struct__

    queryable
    |> where([q], field(q, ^scope_field) == ^scope_value)
    |> where([s], s.position >= ^new_position)
    |> changeset.repo.update_all(inc: [position: 1])
  end

  defp remove(changeset, scope_field, scope_value, _position_field, old_position) do
    changeset.data.__struct__
    |> where([q], field(q, ^scope_field) == ^scope_value)
    |> where([q], q.position >= ^old_position)
    |> changeset.repo.update_all(inc: [position: -1])
  end
end
