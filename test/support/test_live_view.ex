defmodule LiveViewBindingTest.TestLiveView do
  use Phoenix.LiveView
  use LiveViewBinding

  def render(assigns) do
    ~H"""
    <div id="params"><%= @params |> URI.encode_query() %></div>
    <div id="entity_a"><%= @entity_a %></div>
    <div id="entity_b"><%= @entity_b %></div>
    <div id="entity_c"><%= @entity_c %></div>
    """
  end

  bind :entity_a do
    loader(fn params, uri, _socket ->
      "loader(#{params |> URI.encode_query()}, #{uri})"
    end)

    updater(fn message, _socket ->
      "updater(#{message})"
    end)
  end

  bind :entity_b do
    mapper_of(:entity_a, fn entity_a ->
      "mapper_of(#{entity_a})"
    end)
  end

  bind :entity_c do
    getter()

    mapper(fn socket ->
      (get_current_entity_c(socket) || 0) + 1
    end)
  end
end
