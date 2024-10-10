defmodule ExGitOps.Utils.Validations do
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
end
