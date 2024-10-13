defmodule ExGitOps.GitOps do
  alias ExGitOps.Models.Repo
  @callback get_repos(String.t) :: {:ok,list(Repo.t)} | {:error, String.t}
  @callback clone_all_repos() :: :ok | {:error, String.t}
  @callback clone_repo(Repo.t,[repo_path: String.t()]) :: :ok | {:error, String.t}
  @callback default_repo_path() :: String.t
  @callback user_names():: {:ok,[String.t]} | {:error, String.t}
end
