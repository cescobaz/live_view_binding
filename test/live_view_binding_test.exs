defmodule LiveViewBindingTest do
  use ExUnit.Case
  doctest LiveViewBinding

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint LiveViewBindingTest.Endpoint

  test "greets the world" do
    conn = build_conn()
    {:ok, _view, html} = live(conn, "/greets_the_world")
    assert html =~ "hello world"
  end
end
