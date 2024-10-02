defmodule ManageDevelopmentTest do
  use ExUnit.Case
  doctest ManageDevelopment

  test "greets the world" do
    assert ManageDevelopment.hello() == :world
  end
end
