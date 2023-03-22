defmodule LiveViewBindingTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  scope "/" do
    live_session :test do
      Phoenix.LiveView.Router.live("/test", LiveViewBindingTest.TestLiveView)
    end
  end
end
