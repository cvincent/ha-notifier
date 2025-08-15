import Config
config :ha_notifier, port: System.get_env("PORT", "8124") |> String.to_integer()
config :ha_notifier, notify_send: System.get_env("NOTIFY_SEND")
config :ha_notifier, aplay: System.get_env("APLAY")
