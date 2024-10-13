defmodule ExGitOps.Models.Repo do
  defstruct [:name, :ssh_url]
  @type t :: %__MODULE__{
    name: String.t(),
    ssh_url: String.t()
  }
  def new(), do: __struct__()
  def new(args), do: __struct__(args)


end
