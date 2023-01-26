defmodule LiveViewBindingTest do
  use ExUnit.Case
  doctest LiveViewBinding

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LiveViewBindingTest.Endpoint

  test "greets the world" do
    defmodule AModule do
      use Phoenix.LiveView
      use LiveViewBinding

      def mount(params, _session, socket) do
        {:ok, load_all_resources(socket, params)}
      end

      def render(assigns) do
        ~H"""
        <%= @resource_name %>
        """
      end

      LiveViewBinding.loader(:resource_name, fn _params, _socket ->
        "hello world"
      end)
    end

    conn = build_conn()
    {:ok, _view, html} = live_isolated(conn, AModule)
    assert html =~ "hello world"
  end
end
