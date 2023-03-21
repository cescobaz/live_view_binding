defmodule LiveViewBindingTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_view_binding
  plug(LiveViewBindingTest.Router)
end
