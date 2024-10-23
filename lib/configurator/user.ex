defmodule ExGitOps.Configurator.User do
  @behaviour SystemBehaviour
  alias ExGitOps.Models.User
  require Logger

  def set_user(%User{} = user, opts \\ []) do
    user
    |> apply_changes(opts)
  end

  defp apply_changes(%User{} = user, opts \\ []) do
    user
    |> Map.from_struct()
    |> Stream.filter(fn {_key, value} -> not is_nil(value) end)
    |> Enum.map(fn {key, value} -> apply_change(key, value, opts) end)
    |> filter_results()
  end

  def apply_change(key, value, opts \\ []) do
    try do
      save_config(key, value, opts)
      |> case do
        {"", 0} ->
          {:ok, "User #{key} {#{value}} has been successfully configured."}

        {:error, error} ->
          {:error, error}

        error ->
          Logger.error(
            "Failed to configure #{inspect(key)} #{inspect(value)} locally. Error: #{inspect(error)}."
          )

          {:error, "User #{key} was not configured successfully."}
      end
    rescue
      ErlangError ->
        {:error, "An unexpected error has occurred. Please verify that Git is installed."}
    end
  end

  defp save_config(key, value, opts \\ []) do
    repo_path = Keyword.get(opts, :repo_path)
    IO.inspect(repo_path)

    if is_nil(repo_path) do
      Logger.info("Saving config globally: #{inspect(key)} #{inspect(value)}")
      cmd("git", ["config", "--global", "user.#{key}", value])
    else
      save_config_local(key, value, repo_path)
    end
  end

  defp save_config_local(key, value, repo_path) when is_binary(repo_path) do
    dir_exists = File.dir?(repo_path)

    with :ok <-
           ExGitOps.Utils.Validations.validate(
             dir_exists,
             "The specified directory #{repo_path} could not be found."
           ),
         :ok <-
           ExGitOps.Utils.Validations.validate(
             ExGitOps.Utils.Validations.valid_git_repo?(repo_path),
             "The specified directory #{repo_path} is not a valid git directory."
           ) do
      Logger.info("Saving config locally: #{inspect(key)} #{inspect(value)}")
      cmd("git", ["config", "--local", "user.#{key}", value], cd: repo_path)
    else
      err -> err
    end
  end

  def filter_results(results) do
    {successes, errors} =
      Enum.split_with(results, fn
        {:error, _} -> false
        {:ok, _} -> true
      end)

    case errors do
      [] ->
        {:ok, get_status_message(successes)}

      [_ | _] ->
        {:error, String.trim(get_status_message(successes) <> " " <> get_status_message(errors))}
    end
  end

  def get_status_message(statuses) when is_list(statuses) do
    Enum.map_join(statuses, " ", &get_status_message/1)
  end

  def get_status_message({:ok, message}) when is_binary(message), do: message
  def get_status_message({:error, message}) when is_binary(message), do: message


  @impl SystemBehaviour
  @spec cmd(binary(), [binary()], keyword()) ::
          {Collectable.t(), exit_status :: non_neg_integer()}
  defp cmd(command, args, opts \\ []) do
    impl = Application.get_env(:configurator, :cmd, System)
    Logger.info("Using #{inspect(impl)} as SystemBehavior implementation.")
    impl.cmd(command, args, opts)
  end
end
