defmodule PmLogin.SpawnerLauncher do
  use GenServer
  alias PmLogin.Monitoring

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    #STRING TO PID
    # pid("0.2190.0")
    # START CHILDREN BENEATH SPAWNER SUPERVISOR
    # DynamicSupervisor.start_child(PmLogin.SpawnerSupervisor, %{id: PmLogin.TaskSpawner, start: {PmLogin.TaskSpawner, :start_link, [%{key: "value"}]} })

    #GET PID STATE
    #:sys.get_state(pid)


    # for i <- 1..10 do
    #   DynamicSupervisor.start_child(PmLogin.SpawnerSupervisor, %{id: PmLogin.TaskSpawner, start: {PmLogin.TaskSpawner, :start_link, [%{name: "#{i}"}]} })
    # end

    tasks = Monitoring.list_planified

    for task <- tasks do
      DynamicSupervisor.start_child(PmLogin.SpawnerSupervisor, %{id: PmLogin.TaskSpawner, start: {PmLogin.TaskSpawner, :start_link, [%{planified: task}]} })
    end

    {:ok, state}
  end

end
