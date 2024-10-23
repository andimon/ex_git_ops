defmodule ExGitOps.Utils.Validations do
  alias ExGitOps.RestClient

  def valid_git_repo?(repo_path) when is_binary(repo_path) do
    result = System.cmd("git", ["rev-parse", "--is-inside-work-tree"], cd: repo_path)

    case result do
      {"true\n", 0} -> true
      _ -> false
    end
  end

  def validate(true, _reason), do: :ok
  def validate(false, reason), do: {:error, reason}

  @doc """
  Checks if the Git email for a given user is set in the environment.

  This function takes a `user` (as a string), appends `"_git_email"` to it, and then checks if this environment variable is set. If the environment variable is not set (i.e., it is `nil`), it returns `fale`, indicating the Git email is not set. Otherwise, it returns `true`.

  ## Parameters
    - `user`: A string representing the user for whom to check if the Git email is set.

  ## Returns
    - `true` if the Git email is not set (i.e., the environment variable is `nil`).
    - `false` if the Git email is set.

  ## Examples

      iex> System.put_env("andimon_git_email", "andimon@example.com")
      iex> is_git_email_set("andimon")
      true

      iex> System.delete_env("andimon_git_email")
      iex> is_git_email_set("andimon")
      false
  """
  def is_git_email_set(user) when is_binary(user),
    do: not is_nil(System.get_env(user <> "_git_email"))

  @doc """
  Checks if the Git API token for a given user is set in the environment.

  This function takes a `user` (as a string), appends `"_git_api_token"` to it, and then checks if this environment variable is set. If the environment variable is set (i.e., it is not `nil`), the function returns `true`, indicating the Git API token is present. Otherwise, it returns `false`.

  ## Parameters
    - `user`: A string representing the user for whom to check if the Git API token is set.

  ## Returns
    - `true` if the Git API token is set (i.e., the environment variable is not `nil`).
    - `false` if the Git API token is not set.

  ## Examples

      iex> System.put_env("andimon_git_api_token", "some_token")
      iex> is_git_api_token_set("andimon")
      true

      iex> System.delete_env("andimon_git_api_token")
      iex> is_git_api_token_set("andimon")
      false
  """

  def is_git_api_token_set(user) when is_binary(user),
    do: not is_nil(System.get_env(user <> "_git_api_token"))

  @doc """
  Checks if the Git username for a given user is set in the environment.

  This function takes a `user` (as a string), appends `"_git_username"` to it, and then checks if this environment variable is set. If the environment variable is set (i.e., it is not `nil`), the function returns `true`, indicating the Git username for the given `user` is present. Otherwise, it returns `false`.

  ## Parameters
    - `user`: A string representing the user for whom to check if the Git username is set.

  ## Returns
    - `true` if the Git username is set (i.e., the environment variable is not `nil`).
    - `false` if the Git username is not set.

  ## Examples

      iex> System.put_env("andimon_git_username", "some_token")
      iex> is_git_api_token_set("andimon")
      true

      iex> System.delete_env("andimon_git_username")
      iex> is_git_api_token_set("andimon")
      false
  """

  def is_git_username_set(user) when is_binary(user),
    do: not is_nil(System.get_env(user <> "_git_username"))

  def is_git_api_token_valid(user) do
    with :ok <- validate(is_git_api_token_set(user), :git_api_key_not_set) do
      RestClient.get("https://api.github.com/user", headers(user), params())
      |> case do
        {:ok, %Req.Response{status: 200}} ->
          true

        _else ->
          false
      end
    else
      {:error, :git_api_key_not_set} -> false
    end
  end

  # @TODO remove repetition
  defp headers(user) do
    [
      Accept: "application/vnd.github+json",
      Authorization: "Bearer #{get_git_user_api_token(user)}",
      "X-GitHub-Api-Version": "2022-11-28"
    ]
  end

  def params() do
    [
      type: "all"
    ]
  end

  defp get_git_user_api_token(user), do: System.get_env("#{user}_git_api_token")
end
