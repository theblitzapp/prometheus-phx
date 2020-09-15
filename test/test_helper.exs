ExUnit.start()

# Set the config for the prometheus-phx test web application
Application.put_env(:prometheus_phx_test, PrometheusPhxTestWeb.Endpoint,
  pubsub_server: PrometheusPhxTest.PubSub,
  render_errors: [
    view: PrometheusPhxTestWeb.ErrorView,
    accepts: ~w(html json),
    layout: false
  ],
  server: false,
  debug_errors: false
)

# Make sure everything is started
Application.ensure_started(:logger)
Application.ensure_started(:plug)
Application.ensure_started(:phoenix)

# Start the web application
PrometheusPhxTest.Application.start(nil, nil)
