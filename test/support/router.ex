defmodule LiveViewBindingTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  scope "/" do
    live_session :test do
      Phoenix.LiveView.Router.live("/greets_the_world", LiveViewBindingTest.GreetsTheWorld)
    end
  end
end
