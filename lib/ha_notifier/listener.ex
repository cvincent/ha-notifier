defmodule HANotifier.Listener do
  require Logger

  use Task, restart: :transient

  def start_link(port \\ 8124) do
    Task.start_link(__MODULE__, :accept, [port])
  end

  def accept(port) do
    Logger.info("Connecting...")

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Listening on #{port}...")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    Logger.info("Waiting...")
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(client) do
    {:ok, data} = :gen_tcp.recv(client, 0)
    Logger.info("recv: #{String.trim(data)}")
    handle_line(client, data)
  end

  defp handle_line(client, "GET /notifications?" <> rest) do
    [query, "HTTP/1.1"] = String.split(rest)

    message = URI.decode_query(query)

    data =
      message["data"]
      |> String.replace("'", "\"")
      |> Jason.decode!()

    message = put_in(message["data"], data)

    Logger.info("Received notification: #{inspect(message)}")

    HANotifier.LibnotifyNotifier.notify(message)

    serve(client)
  end

  defp handle_line(client, "\r\n") do
    :gen_tcp.send(client, "HTTP/1.1 200 OK\r\n")
    :gen_tcp.send(client, "Content-Type: text/plain\r\n")
    :gen_tcp.send(client, "Content-Length: 0\r\n")
    :gen_tcp.send(client, "\r\n")
  end

  defp handle_line(client, _anything_else), do: serve(client)
end
