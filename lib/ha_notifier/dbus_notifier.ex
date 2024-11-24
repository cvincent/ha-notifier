defmodule HANotifier.DBusNotifier do
  # Does not work yet, can't figure out how to set the urgency hint in a way
  # that takes

  defstruct bus: nil,
            service: nil,
            remote_object: nil,
            interface: nil

  require Logger

  use GenServer

  def start_link(nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def notify(message) do
    GenServer.cast(__MODULE__, {:notify, message})
  end

  @dialyzer {:nowarn_function, init: 1}
  def init(nil) do
    {:ok, bus} = :dbus_bus_reg.get_bus(:session)
    {:ok, service} = :dbus_bus.get_service(bus, "org.freedesktop.Notifications")

    {:ok, remote_object} =
      :dbus_remote_service.get_object(service, "/org/freedesktop/Notifications")

    {:ok, interface} = :dbus_proxy.interface(remote_object, "org.freedesktop.Notifications")

    {:ok,
     %__MODULE__{
       bus: bus,
       service: service,
       remote_object: remote_object,
       interface: interface
     }}
  end

  # Unable to get urgency to work...
  @dialyzer {:nowarn_function, handle_cast: 2}
  def handle_cast({:notify, message}, state) do
    Logger.info("Sending notification: #{inspect(message)}")

    :dbus_proxy.call(
      state.interface,
      "Notify",
      [
        "ha_notifier",
        2,
        "dialog-information",
        message["title"],
        message["message"],
        ["Open"],
        %{"nonsense" => 2},
        0
      ]
    )
    |> dbg()

    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.info("Terminating notifier: #{reason}")
    :dbus_remote_service.release_object(state.service, state.remote_object)
    :dbus_bus.release_service(state.bus, state.service)
  end
end
