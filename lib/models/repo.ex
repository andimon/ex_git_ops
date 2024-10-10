defmodule ManageDevelopment.Models.Repo do
  defstruct [:name, :ssh_url]
  def new(), do: __struct__()
  def new(args), do: __struct__(args)


end
