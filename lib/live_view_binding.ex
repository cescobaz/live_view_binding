defmodule LiveViewBinding do
  @doc false
  defmacro __init_attributes__(module) do
    module = Macro.expand(module, __CALLER__)
    Module.put_attribute(module, :load_fns, [])
    Module.put_attribute(module, :reload_fns, [])
    Module.put_attribute(module, :mapper_fns, [])
    Module.put_attribute(module, :release_fns, [])
  end

  defmacro __using__(_opts) do
    m = __MODULE__

    quote do
      import LiveViewBinding

      unquote(m).__init_attributes__(__MODULE__)

      on_mount({__MODULE__, :bind_handle_params})
      on_mount({__MODULE__, :bind_handle_info})

      @before_compile LiveViewBinding
    end
  end

  defmacro __before_compile__(_env) do
    m = __MODULE__

    quote do
      def on_mount(:bind_handle_params, _params, _session, socket) do
        {:cont, unquote(m).attach_handle_params_hook(socket, __MODULE__, @load_fns, @mapper_fns)}
      end

      def on_mount(:bind_handle_info, _params, _session, socket) do
        {:cont, unquote(m).attach_handle_info_hook(socket, __MODULE__, @reload_fns, @mapper_fns)}
      end

      def load_all_resources(socket, params, uri \\ nil) do
        unquote(m).load_all_resources(socket, params, uri, __MODULE__, @load_fns, @mapper_fns)
      end

      def reload_all_resources(socket, message) do
        unquote(m).reload_all_resources(socket, message, __MODULE__, @reload_fns, @mapper_fns)
      end

      def release_all_resources(socket) do
        unquote(m).release_all_resources(socket, __MODULE__, @release_fns)
      end

      def terminate(_reason, socket) do
        unquote(m).release_all_resources(socket, __MODULE__, @release_fns)
      end

      defoverridable terminate: 2
    end
  end

  @doc false
  def load_all_resources(socket, params, uri, module, fns, mapper_fns) do
    fns
    |> Enum.reverse()
    |> Enum.reduce(socket, fn name, socket ->
      apply(module, name, [socket, params, uri])
    end)
    |> run_all_mappers(module, mapper_fns)
    |> Phoenix.Component.assign(:params, params)
    |> Phoenix.Component.assign(:uri, uri)
  end

  @doc false
  def reload_all_resources(socket, message, module, fns, mapper_fns) do
    fns
    |> Enum.reverse()
    |> Enum.reduce(socket, fn name, socket ->
      apply(module, name, [socket, message])
    end)
    |> run_all_mappers(module, mapper_fns)
  end

  @doc false
  def run_all_mappers(socket, module, fns) do
    fns
    |> Enum.reverse()
    |> Enum.reduce(socket, fn name, socket ->
      apply(module, name, [socket])
    end)
  end

  @doc false
  def release_all_resources(socket, module, fns) do
    fns
    |> Enum.reduce(socket, fn name, socket ->
      apply(module, name, [socket])
    end)
  end

  @doc false
  def attach_handle_params_hook(socket, module, fns, mappers) do
    Phoenix.LiveView.attach_hook(socket, :live_view_binding_params, :handle_params, fn params,
                                                                                       uri,
                                                                                       socket ->
      {:cont, load_all_resources(socket, params, uri, module, fns, mappers)}
    end)
  end

  @doc false
  def attach_handle_info_hook(socket, module, fns, mappers) do
    Phoenix.LiveView.attach_hook(socket, :live_view_binding_info, :handle_info, fn message,
                                                                                   socket ->
      {:cont, reload_all_resources(socket, message, module, fns, mappers)}
    end)
  end

  defp concat_to_atom(string, atom) when is_binary(string) and is_atom(atom) do
    (string <> Atom.to_string(atom))
    |> String.to_atom()
  end

  @doc false
  defmacro __bind__(module, key, do: block) do
    module = Macro.expand(module, __CALLER__)
    Module.put_attribute(module, :key, key)

    quote do
      unquote(block)
    end
  end

  defmacro bind(key, do: block) do
    m = __MODULE__

    quote do
      unquote(m).__bind__ __MODULE__, unquote(key) do
        unquote(block)
      end
    end
  end

  @doc false
  defmacro __bind_fn__(module, fn_prefix, fn_list_key, do: block) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)

    fn_name = concat_to_atom(fn_prefix, key)
    Module.put_attribute(module, :fn_name, fn_name)

    if fn_list_key != nil do
      fn_list = Module.get_attribute(module, fn_list_key)
      Module.put_attribute(module, fn_list_key, [fn_name | fn_list])
    end

    quote do
      unquote(block)
    end
  end

  @doc false
  defmacro __getter__(module) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    quote do
      def unquote(fn_name)(socket) do
        Map.get(socket.assigns, unquote(key))
      end
    end
  end

  defmacro getter do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "get_current_", nil do
        unquote(m).__getter__(__MODULE__)
      end
    end
  end

  @doc false
  defmacro __assigner__(module) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    quote do
      def unquote(fn_name)(socket, value) do
        Phoenix.Component.assign(socket, unquote(key), value)
      end
    end
  end

  defmacro assigner do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "assign_", nil do
        unquote(m).__assigner__(__MODULE__)
      end
    end
  end

  @doc false
  def apply_fn(fn_arg, args) when is_list(args) do
    args_count = Enum.count(args)

    case fn_arg do
      {module, fn_atom} -> apply(module, fn_atom, args)
      anonymous_fn when is_function(anonymous_fn, args_count) -> apply(anonymous_fn, args)
    end
  end

  @doc false
  def apply_loader(loader_fn, params, uri, socket) do
    case loader_fn do
      {module, fn_atom} -> apply(module, fn_atom, [params, uri, socket])
      anonymous_fn when is_function(anonymous_fn, 3) -> anonymous_fn.(params, uri, socket)
      anonymous_fn when is_function(anonymous_fn, 2) -> anonymous_fn.(params, socket)
    end
  end

  @doc false
  defmacro __loader__(module, loader_fn) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    m = __MODULE__

    quote do
      def unquote(fn_name)(socket, params, uri \\ nil) do
        resource = unquote(m).apply_loader(unquote(loader_fn), params, uri, socket)
        Phoenix.Component.assign(socket, unquote(key), resource)
      end
    end
  end

  defmacro loader(loader_fn) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "load_", :load_fns do
        unquote(m).__loader__(__MODULE__, unquote(loader_fn))
      end
    end
  end

  @doc false
  defmacro __default_loader__(module, default_value) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    quote do
      def unquote(fn_name)(socket, params, uri \\ nil) do
        resource =
          if not Map.has_key?(socket.assigns, unquote(key)) do
            unquote(default_value)
          else
            Map.get(socket.assigns, unquote(key))
          end

        Phoenix.Component.assign(socket, unquote(key), resource)
      end
    end
  end

  defmacro default(default_value) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "default_loader_", :load_fns do
        unquote(m).__default_loader__(__MODULE__, unquote(default_value))
      end
    end
  end

  @doc false
  defmacro __updater__(module, updater_fn) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    m = __MODULE__

    quote do
      def unquote(fn_name)(socket, message) do
        resource = unquote(m).apply_fn(unquote(updater_fn), [message, socket])

        Phoenix.Component.assign(socket, unquote(key), resource)
      end
    end
  end

  defmacro updater(updater_fn) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "update_", :reload_fns do
        unquote(m).__updater__(__MODULE__, unquote(updater_fn))
      end
    end
  end

  @doc false
  defmacro __mapper_of__(module, of_assign, mapper_fn) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    m = __MODULE__

    quote do
      def unquote(fn_name)(socket) do
        of = Map.get(socket.assigns, unquote(of_assign))
        resource = unquote(m).apply_fn(unquote(mapper_fn), [of])

        Phoenix.Component.assign(socket, unquote(key), resource)
      end
    end
  end

  defmacro mapper_of(of_assign, mapper_fn) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "map_", :mapper_fns do
        unquote(m).__mapper_of__(__MODULE__, unquote(of_assign), unquote(mapper_fn))
      end
    end
  end

  @doc false
  defmacro __mapper__(module, mapper_fn) do
    module = Macro.expand(module, __CALLER__)
    key = Module.get_attribute(module, :key)
    fn_name = Module.get_attribute(module, :fn_name)

    m = __MODULE__

    quote do
      def unquote(fn_name)(socket) do
        resource = unquote(m).apply_fn(unquote(mapper_fn), [socket])
        Phoenix.Component.assign(socket, unquote(key), resource)
      end
    end
  end

  defmacro mapper(mapper_fn) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "map_", :mapper_fns do
        unquote(m).__mapper__(__MODULE__, unquote(mapper_fn))
      end
    end
  end

  @doc false
  defmacro __terminator__(module, terminator_fn) do
    fn_name =
      Macro.expand(module, __CALLER__)
      |> Module.get_attribute(:fn_name)

    m = __MODULE__

    quote do
      def unquote(fn_name)(socket) do
        unquote(m).apply_fn(unquote(terminator_fn), [socket])
      end
    end
  end

  defmacro terminator(terminator_fn) do
    m = __MODULE__

    quote do
      unquote(m).__bind_fn__ __MODULE__, "terminate_", :release_fns do
        unquote(m).__terminator__(__MODULE__, unquote(terminator_fn))
      end
    end
  end
end
