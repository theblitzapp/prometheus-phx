defmodule PrometheusPhx do
  @moduledoc """
  Handle the telemetry messages broadcasted from Phoenix

  To attach to the Phoenix telemetry messages call the `setup/0` function. Then the handlers will receive the messages and write to prometheus.
  """
  use Prometheus.Metric

  require Prometheus.Contrib.HTTP
  alias Prometheus.Contrib.HTTP

  @duration_unit :microseconds

  def setup do
    events = [
      [:phoenix, :router_dispatch, :stop],
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

  def handle_event([:phoenix, :router_dispatch, :stop], %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Histogram.observe(
        [
          name: :"phoenix_controller_call_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event([:phoenix, :error_rendered], %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Histogram.observe(
        [
          name: :"phoenix_controller_error_rendered_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event([:phoenix, :channel_joined], %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Histogram.observe(
        [
          name: :"phoenix_channel_join_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event(
        [:phoenix, :channel_handled_in],
        %{duration: duration},
        metadata,
        _config
      ) do
    with labels when is_list(labels) <- labels(metadata) do
      Histogram.observe(
        [
          name: :"phoenix_channel_receive_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def labels(%{
        status: status,
        conn: %{private: %{phoenix_action: action, phoenix_controller: controller}}
      }) do
    [action, controller, status]
  end

  def labels(%{
        conn: %{
          status: status,
          private: %{phoenix_action: action, phoenix_controller: controller}
        }
      }) do
    [action, controller, status]
  end

  def labels(%{status: status, stacktrace: [{module, function, _, _} | _]}) do
    [function, module, status]
  end

  def labels(%{event: event, socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport, event]
  end

  def labels(%{socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport]
  end

  def labels(_metadata), do: nil
end
