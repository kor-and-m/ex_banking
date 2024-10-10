defmodule ExBanking.Utils do
  @moduledoc false

  def user_name_to_atom(user_name) do
    server_name = user_name |> user_name_to_server_name() |> String.to_existing_atom()
    {:ok, server_name}
  rescue
    _e in ArgumentError -> {:error, :user_does_not_exist}
  end

  def user_name_to_atom!(user_name),
    do: user_name |> user_name_to_server_name() |> String.to_atom()

  defp user_name_to_server_name(user_name), do: "user_#{user_name}"
end
