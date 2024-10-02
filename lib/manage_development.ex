defmodule ManageDevelopment do
  @default_ssh_path "~/.ssh/config"

  def get_github_hosts(opts \\ []) do
    read_ssh_config(opts)
    |> Stream.filter(fn x -> is_github_host?(x) end)
    |> Enum.into(%{})
  end

  defp is_github_host?({_,host_details}) do
    host_details
    |> Keyword.get(:host_name)
    |> (&(&1=="github.com")).()
  end


  def read_ssh_config(opts \\ []) do
    expanded_path = Path.expand(get_path(opts))
    case File.read(expanded_path) do
      {:ok, content} ->
        parse_ssh_config(content)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def parse_ssh_config(config_text) do
    config_text
    |> String.split("\n")
    |> Enum.map(&preprocess_line/1)
    |> Enum.reduce({[], nil, nil}, &parse_reducer/2)
    |> complete
  end

  defp complete({_, nil, nil}), do: %{}
  defp complete({kw_so_far, this_name, this_kw}) do
    kw_so_far
    |> Kernel.++([{this_name, this_kw}])
    |> Enum.map(fn
      {host, kw} ->
        keymap = kw |> Enum.map(&adjust/1)
        {host, keymap} end)
    |> Enum.into(%{})
  end

  defp preprocess_line(val) do
    val
    |> String.trim
    |> String.split("#", parts: 2) # handle commented lines by splitting and
    |> Enum.at(0)                  # ignoring anything past the octothorpe
  end

  defp parse_reducer("Host " <> hostname, {kw_so_far, nil, nil}) do
    {kw_so_far, hostname, []}
  end
  defp parse_reducer("Host " <> hostname, {kw_so_far, this_name, this_kw}) do
    {kw_so_far ++ [{this_name, this_kw}], String.trim(hostname), []}
  end
  defp parse_reducer("", acc), do: acc
  defp parse_reducer(_other, {_, nil, nil}), do: raise "error parsing ssh config file, must begin with a Host statement"
  defp parse_reducer(other, acc = {kw_so_far, this_name, this_map}) do
    other
    |> String.split(~r/\s/, parts: 2)
    |> case do
      [string_key, value] ->
        atom_key = string_key |> Macro.underscore |> String.to_atom
        {kw_so_far, this_name, this_map ++ [{atom_key, value}]}
      [""] -> acc
      [string] -> raise "error parsing ssh config: stray config #{string}"
    end
  end


  @boolean_keys [:hash_based_authentication, :strict_host_key_checking]

  @second_keys [:connect_timeout]
  defp adjust({key, v}) when key in @second_keys do
    {key, String.to_integer(v) * 1000}
  end
  defp adjust({key, v}) when key in @boolean_keys do
    {key, boolean(v)}
  end
  defp adjust(any), do: any

  defp boolean("yes"), do: true
  defp boolean("no"), do: false

  defp get_path([{:ssh_path, path}]) when is_binary(path), do: path
  defp get_path(_), do: @default_ssh_path
end
