defmodule PmLogin.DatabaseBackup do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    backup_database(state)
    {:ok, state}
  end

  defp backup_database(_state) do
    naive_dt_now = NaiveDateTime.local_now()

    date = Date.utc_today() |> Date.to_iso8601()

    time = "17:00:00"
    time_to_start_once_again = "18:00:00"

    date_time_to_start = date <> " " <> time |> NaiveDateTime.from_iso8601!()
    date_time_to_start_again = date <> " " <> time_to_start_once_again |> NaiveDateTime.from_iso8601!()

    cond do
      naive_dt_now == date_time_to_start ->
        commands = "PGPASSWORD=postgres pg_dump -h localhost -U postgres -d pm_users -f PM_USERS_BACKUP_#{date <> "_" <> time}.sql"

        System.shell(commands)

        IO.inspect("Backup finished at #{date <> " " <> time}...")

        Process.send_after(self(), :start_backup_after, 1000)

      naive_dt_now == date_time_to_start_again ->
        commands = "PGPASSWORD=postgres pg_dump -h localhost -U postgres -d pm_users -f PM_USERS_BACKUP_#{date <> "_" <> time_to_start_once_again}.sql"

        System.shell(commands)

        IO.inspect("Backup once again finished at #{date <> " " <> time_to_start_once_again}...")

        Process.send_after(self(), :start_backup_after, 1000)
      true ->
        Process.send_after(self(), :start_backup_after, 1000)
    end

  end

  def handle_info(:start_backup_after, state) do
    init(state)
    {:noreply, state}
  end
end
