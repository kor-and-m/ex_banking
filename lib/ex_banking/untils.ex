defmodule ExBanking.Utils do
  @moduledoc false

  def user_name_to_server_name(user_name), do: "user_#{user_name}"
end
