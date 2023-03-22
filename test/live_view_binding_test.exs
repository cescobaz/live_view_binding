defmodule LiveViewBindingTest do
  use ExUnit.Case
  doctest LiveViewBinding

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias LiveViewBindingTest.Router.Helpers, as: Routes
  alias LiveViewBindingTest.TestLiveView

  @endpoint LiveViewBindingTest.Endpoint

  test "greets the world" do
    conn = build_conn()
    path = Routes.live_path(conn, TestLiveView, %{key: "value"})
    {:ok, view, html} = live(conn, path)
    assert html =~ "loader(key=value,"

    send(view.pid, :hello)
    assert render(view) =~ "updater(hello)"
  end
end
