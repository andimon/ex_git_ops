Mox.defmock(SystemBehaviourMock, for: SystemBehaviour)
Application.put_env(:configurator, :cmd, SystemBehaviourMock)
ExUnit.start()
