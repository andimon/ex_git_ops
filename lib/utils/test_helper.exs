Mox.defmock(SystemBehaviourMock, for: SystemBehaviour)
Application.put_env(:bound, :System, SystemBehaviourMock)
ExUnit.start()
