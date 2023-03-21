defmodule PmLogin.TaskSpawner do
  use GenServer
  alias PmLogin.Utilities
  alias PmLogin.Monitoring

  def start_link(opts) do
    # IO.inspect opts
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    # schedule_work(state)
    # spawning(state)
    schedule_spawn(state)
    {:ok, state}
  end


  defp schedule_spawn(state) do

    dt_start = state[:planified].dt_start
    period = state[:planified].period

    IO.inspect dt_start

    diff = NaiveDateTime.diff(dt_start, NaiveDateTime.local_now())
    IO.inspect(diff)

    next_end = cond do
      diff > 0 ->
        IO.puts "dt_start"
        dt_start

      true ->
        IO.puts "next_end"
        Utilities.next_end(dt_start, period)
    end

    IO.inspect(next_end)

    until_next_end = NaiveDateTime.diff(next_end, NaiveDateTime.local_now())
    IO.inspect(until_next_end)
    Process.send_after(self(), :spawn_work,  until_next_end * 1000)

  end



  def handle_info(:spawn_work, state) do
    do_spawn(state)
    schedule_spawn(state)
    {:noreply, state}
  end

  defp do_spawn(state) do
    Monitoring.spawn_task(state[:planified])
  end

  def spawning(state) do

    dt_start = state[:planified].dt_start
    period = state[:planified].period

    IO.inspect dt_start

    diff = NaiveDateTime.diff(dt_start, NaiveDateTime.local_now())
    IO.inspect(diff)

    next_end = cond do
      diff > 0 ->
        dt_start

      true ->
        Utilities.next_end(dt_start, period)
    end

    IO.inspect(next_end)

    until_next_end = NaiveDateTime.diff(next_end, NaiveDateTime.local_now())
    IO.inspect(until_next_end)
    Process.send_after(self(), :spawn_work,  until_next_end * 1000)

  end


  def handle_info(:work, state) do
    recurrent_work(state)
    schedule_work(state)
    {:noreply, state}
  end

  defp schedule_work(state) do
    # In 2 hours
    # Process.send_after(self(), :work, 2 * 60 * 60 * 1000)


    Process.send_after(self(), :work,  5 * 1000)
  end

  defp recurrent_work(state) do
    # IO.inspect state[:planified]
    planified = state[:planified]
    planified_map = Map.from_struct(planified)
    IO.inspect planified_map
    # Monitoring.spawn_task(planified)
  end

end
