defmodule LiveViewBinding do
  @moduledoc """
  Documentation for `LiveViewBinding`.
  """

  defmacro __using__(_env) do
    quote do
      require LiveViewBinding

      @load_fns []
      @reload_fns []
      @release_fns []

      @before_compile LiveViewBinding
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def load_all_resources(socket, params) do
        @load_fns
        |> Enum.reverse()
        |> Enum.reduce(socket, fn name, socket ->
          apply(__MODULE__, name, [socket, params])
        end)
        |> Phoenix.Component.assign(:params, params)
      end

      def reload_all_resources(socket, message) do
        @reload_fns
        |> Enum.reverse()
        |> Enum.reduce(socket, fn name, socket ->
          apply(__MODULE__, name, [socket, message])
        end)
      end

      def release_all_resources(socket) do
        @release_fns
        |> Enum.reduce(socket, fn name, socket ->
          apply(__MODULE__, name, [socket])
        end)
      end

      def attach_hooks(socket) do
        socket
        |> Phoenix.LiveView.attach_hook(:my_hook, :handle_params, fn params, socket ->
          {:cont, apply(__MODULE__, :load_all_resources, [socket, params])}
        end)
      end

      def mount(_params, _session, socket) do
        {:ok, apply(__MODULE__, :attach_hooks, [socket])}
      end

      defoverridable mount: 3
    end
  end

  defmacro loader(resource_name_atom, resource_loader_fn) when is_atom(resource_name_atom) do
    resource_name = Atom.to_string(resource_name_atom)
    load_resource_fn_name = String.to_atom("load_" <> resource_name)

    quote do
      @load_fns [unquote(load_resource_fn_name) | @load_fns]

      def unquote(load_resource_fn_name)(socket, params) do
        resource = unquote(resource_loader_fn).(params, socket)
        Phoenix.Component.assign(socket, unquote(resource_name_atom), resource)
      end
    end
  end
end
