import Config
config :ha_notifier, port: System.get_env("PORT", "8124") |> String.to_integer()