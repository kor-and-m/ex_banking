defmodule ExBanking do
  @moduledoc false

  alias ExBanking.Account
  alias ExBanking.Supervisor

  def create_user(user) when is_binary(user) do
    case Supervisor.start_child(user) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount),
      do: Account.deposit(user, currency, amount)

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  def withdraw(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount),
      do: Account.withdraw(user, currency, amount)

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  def get_balance(user, currency) when is_binary(user) and is_binary(currency),
    do: Account.get_balance(user, currency)

  def get_balance(_, _), do: {:error, :wrong_arguments}

  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_binary(currency) and
             is_number(amount),
      do: from_user |> Account.transfer(to_user, currency, amount) |> wrap_transfer()

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  defp wrap_transfer({:error, :user_does_not_exist}), do: {:error, :sender_does_not_exist}
  defp wrap_transfer({:error, :too_many_requests_to_user}), do: {:error, :too_many_requests_to_sender}
  defp wrap_transfer(res), do: res
end
