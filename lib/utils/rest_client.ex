defmodule ExGitOps.RestClient do
  def get(uri, headers, params) do
    Req.get(uri, headers: headers, params: params)
  end
end
