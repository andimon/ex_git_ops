defmodule ExGitOps do
  alias ExGitOps.Models.Repo
  alias ExGitOps.Models
  alias ExGitOps.Configurator
  alias ExGitOps.RestClient
  @default_ssh_path "~/.ssh/config"
  @default_repo_path "../"

  @doc """
  Sets the GIT user information globally or locally within a specified repository.

  If no `repo_path` is provided, the user configuration is applied globally. If a `repo_path` is provided, the user configuration will only apply within the specified GIT repository.

  ## Parameters

  * `user` - A `%ExGitOps.Models.User{}` struct representing the user information to be configured (e.g., name, email).
  * `opts` - A keyword list of options.

  ## Options

  * `:repo_path` - A string specifying the path to the GIT repository where the user configuration should be applied locally. If omitted, the configuration is applied globally.

  ## Example

  ```elixir
  # Configure user globally
  set_user(%ExGitOps.Models.User{name: "John Doe", email: "john@example.com"})

  # Configure user for a specific repository
  set_user(%Models.User{name: "John Doe", email: "john@example.com"}, repo_path: "/path/to/repo")
  """

  def set_user(%Models.User{} = user, opts \\ []) do
    Configurator.User.set_user(user, opts)
  end

  @doc """
  Sets the GIT user's email configuration globally or locally, based on the provided options.

  If no `repo_path` is specified, the email configuration is applied globally. If a `repo_path` is provided, the email is configured for the specified GIT repository.

  ## Parameters

  * `email` - A string representing the email address to be configured.
  * `opts` - A keyword list of options.

  ## Options

  * `:repo_path` - A string specifying the path to the GIT repository where the email configuration should be applied locally. If omitted, the email is configured globally.

  ## Example

  ```elixir
  # Set email globally
  set_user_email("john@example.com")

  # Set email for a specific repository
  set_user_email("john@example.com", repo_path: "/path/to/repo")
  """
  def set_user_email(email, opts \\ []) do
    Models.User.new()
    |> Models.User.set_email(email)
    |> set_user(opts)
  end

  @doc """
  Sets the GIT username configuration globally or locally, based on the provided options.

  If no `repo_path` is specified, the username configuration is applied globally. If a `repo_path` is provided, the username is configured for the specified GIT repository.

  ## Parameters

  * `name` - A string representing the username to be configured.
  * `opts` - A keyword list of options.

  ## Options

  * `:repo_path` - A string specifying the path to the GIT repository where the username configuration should be applied locally. If omitted, the username is configured globally.

  ## Example

  ```elixir
  # Set username globally
  set_user_name("John Doe")

  # Set username for a specific repository
  set_user_name("John Doe", repo_path: "/path/to/repo")
  """
  def set_user_name(name, opts \\ []) do
    Models.User.new()
    |> Models.User.set_name(name)
    |> set_user(opts)
  end

  def clone_all_repos(opts \\ []) do
    get_host_names()
    |> Stream.flat_map(&get_repos/1)
    |> Enum.each(fn repo -> clone_repo(repo, opts) end)
  end

  def clone_repo(%{"ssh_url" => ssh_url}, opts) do
    System.cmd("git", ["clone", ssh_url], cd: repo_path(opts))
  end

  def repo_path(opts) do
    if Keyword.has_key?(opts, :repo_path) do
      Keyword.get(opts, :repo_path)
    else
      @default_repo_path
    end
  end

  def get_host_names() do
    Map.keys(get_github_hosts())
  end

  def get_repos(host_name) when is_binary(host_name) do
    {:ok, %{status: 200, body: body}} =
      RestClient.get("https://api.github.com/user/repos", headers(host_name), params())

    body
    |> Enum.map(fn repo -> filter_repo_info(repo, host_name) end)
  end

  defp headers(user) do
    [
      Accept: "application/vnd.github+json",
      Authorization: "Bearer #{get_git_user_api_token(user)}",
      "X-GitHub-Api-Version": "2022-11-28"
    ]
  end

  defp params() do
    [
      type: "all"
    ]
  end

  def filter_repo_info(%{"name" => name, "ssh_url" => ssh_url}, user) do
    Repo.new(name: name, ssh_url: filter_ssh(ssh_url, user))
  end

  defp filter_ssh(ssh_url, user)
       when is_binary(ssh_url) and is_binary(user) and is_binary(user) do
    String.replace(ssh_url, "github.com", user)
  end

  def get_github_hosts(opts \\ []) do
    read_ssh_config(opts)
    |> Stream.filter(fn x -> is_github_host?(x) end)
    |> Enum.into(%{})
  end

  defp is_github_host?({_, host_details}) do
    host_details
    |> Keyword.get(:host_name)
    |> (&(&1 == "github.com")).()
  end

  @spec read_ssh_config() :: any()
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
        {host, keymap}
    end)
    |> Enum.into(%{})
  end

  defp preprocess_line(val) do
    val
    |> String.trim()
    # handle commented lines by splitting and
    |> String.split("#", parts: 2)
    # ignoring anything past the octothorpe
    |> Enum.at(0)
  end

  defp parse_reducer("Host " <> hostname, {kw_so_far, nil, nil}) do
    {kw_so_far, hostname, []}
  end

  defp parse_reducer("Host " <> hostname, {kw_so_far, this_name, this_kw}) do
    {kw_so_far ++ [{this_name, this_kw}], String.trim(hostname), []}
  end

  defp parse_reducer("", acc), do: acc

  defp parse_reducer(_other, {_, nil, nil}),
    do: raise("error parsing ssh config file, must begin with a Host statement")

  defp parse_reducer(other, acc = {kw_so_far, this_name, this_map}) do
    other
    |> String.split(~r/\s/, parts: 2)
    |> case do
      [string_key, value] ->
        atom_key = string_key |> Macro.underscore() |> String.to_atom()
        {kw_so_far, this_name, this_map ++ [{atom_key, value}]}

      [""] ->
        acc

      [string] ->
        raise "error parsing ssh config: stray config #{string}"
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

  defp get_git_user_api_token(user), do: System.get_env("#{user}_api_token")

  defp boolean("yes"), do: true
  defp boolean("no"), do: false

  defp get_path([{:ssh_path, path}]) when is_binary(path), do: path
  defp get_path(_), do: @default_ssh_path
end
