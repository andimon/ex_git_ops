defmodule ExGitOps.Configurator.User do
  alias ExGitOps.Models.User

  def set_user(%User{} = user, opts \\ []) do
    user
    |> apply_changes()
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
      System.cmd("git", ["config", "--global", "user.#{key}", value])
      |> case do
        {"", 0} -> {:ok, "User #{key} has been successfully configured."}
        _ -> {:error, "User #{key} was not configured successfully."}
      end
    rescue
      ErlangError ->
        {:error, "An unexpected error has occurred. Please verify that Git is installed."}
    end
  end

  def filter_results(results) do
    {successes, errors} =
      Enum.split_with(results, fn
        {:error, _} -> false
        {:ok, _} -> true
      end)

    case errors do
      [] -> {:ok, get_status_message(successes)}
      [_ | _] -> {:error, get_status_message(successes) + " " + get_status_message(errors)}
    end
  end

  def get_status_message(statuses) when is_list(statuses) do
    Enum.map_join(statuses, " ", &get_status_message/1)
  end

  def get_status_message({:ok, message}) when is_binary(message), do: message
  def get_status_message({:error, message}) when is_binary(message), do: message
end
