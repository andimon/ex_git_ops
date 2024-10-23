defmodule ExGitOpsTest do
  use ExUnit.Case

  import Mox
  describe "set_user_email/1" do
    test "configure global user email successfully" do
      expect(SystemBehaviourMock, :cmd, fn command, args, opts  ->
        assert command == "git"
        assert args == ["config","--global","user.email","john.doe@gmail.com"]
        assert opts == []

        {"",0}
      end)

      assert {:ok, "User email {john.doe@gmail.com} has been successfully configured."} = ExGitOps.set_user_email("john.doe@gmail.com")
    end
  end

  describe "set_user_name/1" do
    test "configure global user name successfully" do
      expect(SystemBehaviourMock, :cmd, fn command, args, opts  ->
        assert command == "git"
        assert args == ["config","--global","user.name","JohnDoe"]
        assert opts == []

        {"",0}
      end)

      assert {:ok, "User name {JohnDoe} has been successfully configured."} = ExGitOps.set_user_name("JohnDoe")
    end

    test "configure local user name successfully" do
      expect(SystemBehaviourMock, :cmd, fn command, args, opts  ->
        assert command == "git"
        assert args == ["config","--global","user.name","JohnDoe"]
        assert opts == []

        {"",0}
      end)

      assert {:ok, "User name {JohnDoe} has been successfully configured."} = ExGitOps.set_user_name("JohnDoe",repo_path: "/home/user/test_dir")
    end
  end
end
