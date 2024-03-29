defmodule LiveViewBindingTest.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveViewBindingTest.Endpoint
    ]

    opts = [strategy: :one_for_one, name: LiveViewBindingTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
