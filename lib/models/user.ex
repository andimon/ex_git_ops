defmodule ExGitOps.Models.User do
  defstruct [:name, :email]

  @type t :: %__MODULE__{
          name: String.t(),
          email: String.t()
        }
  def new(), do: __struct__()

  def set_name(%__MODULE__{} = user, name) do
    %{user | name: name}
  end

  def set_email(%__MODULE__{} = user, email) do
    %{user | email: email}
  end
end
