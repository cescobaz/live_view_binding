defmodule LiveViewBindingTest.GreetsTheWorld do
  use Phoenix.LiveView
  use LiveViewBinding

  def render(assigns) do
    ~H"""
    <%= @resource_name %>
    """
  end

  bind :resource_name do
    loader(fn _params, _uri, _socket ->
      "hello world"
    end)
  end
end
