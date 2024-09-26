import Config

config :ex_banking,
  amount_precision: 2,
  requests_per_user_limit: 10,
  requests_timeout: 5_000

import_config "#{config_env()}.exs"
