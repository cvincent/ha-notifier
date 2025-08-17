defmodule HANotifier.LibnotifyNotifier do
  require Logger

  use GenServer

  def start_link({notify_send, aplay}) do
    GenServer.start_link(__MODULE__, {notify_send, aplay}, name: __MODULE__)
  end

  def notify(message) do
    GenServer.cast(__MODULE__, {:notify, message})
  end

  def init({notify_send, aplay}) do
    {:ok, {notify_send, aplay}}
  end

  def handle_cast({:notify, message}, {notify_send, aplay}) do
    Logger.info("Sending notification: #{inspect(message)}")
    System.cmd(notify_send, message_args(message))
    maybe_play_sound(aplay, message)
    {:noreply, notify_send}
  end

  defp message_args(message) do
    icon = message["data"]["icon"]
    icon_file = message["data"]["icon_file"]
    # sound = message["data"]["sound"]

    [
      icon && "--icon=#{icon}",
      icon_file && "--hint=STRING:image-path:#{icon_file}",
      # sound && "--hint=STRING:sound-file:#{sound}",
      message["data"]["transient"] == 1 && "-e",
      message["data"]["urgency"] == 2 && "--urgency=critical",
      message["title"],
      message["message"]
    ]
    |> Enum.filter(& &1)
  end

  defp maybe_play_sound(aplay, %{"data" => %{"sound" => sound_file}}) do
    System.cmd(aplay, [sound_file])
  end

  defp maybe_play_sound(_, _), do: nil
end
