defmodule LiveViewBindingTest.TestLiveView do
  use Phoenix.LiveView
  use LiveViewBinding

  def render(assigns) do
    ~H"""
    <%= @resource_name %>
    """
  end

  bind :resource_name do
    loader(fn params, uri, _socket ->
      "loader(#{params |> URI.encode_query()}, #{uri})"
    end)

    updater(fn message, _socket ->
      "updater(#{message})"
    end)
  end
end
