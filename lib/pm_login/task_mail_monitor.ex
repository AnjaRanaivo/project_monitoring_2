defmodule PmLogin.TaskMailMonitor do
  use GenServer
  alias PmLogin.Monitoring
  alias PmLogin.Email

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    schedule_check()
    {:ok, state}
  end

  def handle_info(:check_tasks, state) do
    # tasks = Monitoring.list_all_tasks_with_card()

    recently_in_control_tasks = Monitoring.list_tasks_recently_in_control

    tasks_with_upcoming_deadline = Monitoring.list_tasks_with_upcoming_deadline

    # tasks = recently_created_tasks ++ tasks_with_upcoming_deadline
    # tasks
    # |> Enum.each(&Email.send_task_mail/1)

    # recently_in_control_tasks
    # |> Enum.each(&Email.send_task_in_control_mail/1)

    Enum.each(recently_in_control_tasks, fn task ->
      Task.start_link(fn -> Email.send_task_in_control_mail(task) end)
      #schedule_check()
    end)

    # tasks_with_upcoming_deadline
    # |> Enum.each(&Email.send_task_in_deadline_mail/1)
    Enum.each(tasks_with_upcoming_deadline, fn task ->
      Task.start_link(fn -> Email.send_task_in_deadline_mail(task) end)
      #schedule_check()
    end)

    #first_task = List.first(tasks_with_upcoming_deadline)
    #Task.start_link(fn -> Email.send_task_in_deadline_mail(first_task) end)

    schedule_check()
    {:noreply, state}
  end

  defp schedule_check() do
    #Process.send_after(self(), :check_tasks, 60_000)
    # in 1 day
    Process.send_after(self(), :work, 24 * 60 * 60 * 1000)
  end

end
