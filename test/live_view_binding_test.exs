defmodule LiveViewBindingTest do
  use ExUnit.Case
  doctest LiveViewBinding

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias LiveViewBindingTest.Router.Helpers, as: Routes
  alias LiveViewBindingTest.TestLiveView

  @endpoint LiveViewBindingTest.Endpoint

  test "loader and updater" do
    conn = build_conn()
    path = Routes.live_path(conn, TestLiveView, %{key: "value"})
    {:ok, view, _html} = live(conn, path)

    assert view
           |> element("#params")
           |> render() =~ ">key=value<"

    assert view
           |> element("#entity_a")
           |> render() =~ "loader(key=value,"

    assert view
           |> element("#entity_b")
           |> render() =~ "mapper_of(loader(key=value,"

    assert view
           |> element("#entity_c")
           |> render() =~ ">1<"

    assert view
           |> element("#entity_d")
           |> render() =~ ">default<"

    send(view.pid, :hello)

    assert view
           |> element("#params")
           |> render() =~ ">key=value<"

    assert view
           |> element("#entity_a")
           |> render() =~ "updater(hello)"

    assert view
           |> element("#entity_b")
           |> render() =~ "mapper_of(updater(hello))"

    assert view
           |> element("#entity_c")
           |> render() =~ ">2<"

    assert view
           |> element("#entity_d")
           |> render() =~ ">default<"

    assert view
           |> element("#entity_d")
           |> render_click() =~ ">click<"
  end
end
