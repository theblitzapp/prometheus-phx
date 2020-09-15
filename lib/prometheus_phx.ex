defmodule PrometheusPhx do
  use Prometheus.Metric

  require Logger
  require Prometheus.Contrib.HTTP
  alias Prometheus.Contrib.HTTP

  @duration_unit :microseconds

  def setup do
    events = [
      [:phoenix, :endpoint, :stop],
      [:phoenix, :error_rendered],
      [:phoenix, :channel_joined],
      [:phoenix, :channel_handled_in]
    ]

    :telemetry.attach_many(
      "telemetry_web__event_handler",
      events,
      &handle_event/4,
      nil
    )

    Histogram.declare(
      name: :"phoenix_controller_call_duration_#{@duration_unit}",
      help: "Whole controller pipeline execution time in #{@duration_unit}.",
      labels: [:action, :controller, :status],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_controller_error_rendered_duration_#{@duration_unit}",
      help: "View error rendering time in #{@duration_unit}.",
      labels: [:action, :controller, :status],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_channel_join_duration_#{@duration_unit}",
      help: "Phoenix channel join handler time in #{@duration_unit}",
      labels: [:channel, :topic, :transport],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_channel_receive_duration_#{@duration_unit}",
      help: "Phoenix channel receive handler time in #{@duration_unit}",
      labels: [:channel, :topic, :transport, :event],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )
  end

  def handle_event([:phoenix, :endpoint, :stop], %{duration: duration}, metadata, _config) do
    labels = labels(metadata)

    Histogram.observe(
      [
        name: :"phoenix_controller_call_duration_#{@duration_unit}",
        labels: labels,
        registry: :default
      ],
      duration
    )
  end

  def handle_event([:phoenix, :error_rendered], %{duration: duration}, metadata, _config) do
    labels = labels(metadata)

    Histogram.observe(
      [
        name: :"phoenix_controller_error_rendered_duration_#{@duration_unit}",
        labels: labels,
        registry: :default
      ],
      duration
    )
  end

  def handle_event([:phoenix, :channel_joined], %{duration: duration}, metadata, _config) do
    labels = labels(metadata)

    Histogram.observe(
      [
        name: :"phoenix_channel_join_duration_#{@duration_unit}",
        labels: labels,
        registry: :default
      ],
      duration
    )
  end

  def handle_event([:phoenix, :channel_handled_in], %{duration: duration}, metadata, _config) do
    labels = labels(metadata)

    Histogram.observe(
      [
        name: :"phoenix_channel_receive_duration_#{@duration_unit}",
        labels: labels,
        registry: :default
      ],
      duration
    )
  end

  def labels(%{
        status: status,
        conn: %{private: %{phoenix_action: action, phoenix_controller: controller}}
      }) do
    [controller, action, status]
  end

  def labels(%{
        conn: %{
          status: status,
          private: %{phoenix_action: action, phoenix_controller: controller}
        }
      }) do
    [controller, action, status]
  end

  def labels(%{status: status, stacktrace: [{module, function, _, _} | _]}) do
    [module, function, status]
  end

  def labels(%{event: event, socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport, event]
  end

  def labels(%{socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport]
  end
end
