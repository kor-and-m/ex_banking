defmodule ExBanking.Wallet do
  @moduledoc false

  @amount_precision 2

  defstruct [:currencies, :locks]

  def new, do: %__MODULE__{currencies: %{}, locks: %{}}

  def get_balance(%__MODULE__{currencies: currencies}, currency) do
    currencies
    |> Map.get(currency, 0.0)
    |> Float.round(@amount_precision)
  end

  def deposit(%__MODULE__{currencies: currencies} = state, currency, amount) do
    current_amount = Map.get(currencies, currency, 0.0)
    %__MODULE__{state | currencies: Map.put(currencies, currency, current_amount + amount)}
  end

  def withdraw(%__MODULE__{currencies: currencies} = state, currency, amount) do
    new_amount = Map.get(currencies, currency, 0.0) - amount

    if new_amount < 0 do
      {:error, :not_enough_money}
    else
      {:ok, %__MODULE__{state | currencies: Map.put(currencies, currency, new_amount)}}
    end
  end

  # lock_ref = make_ref()
  def init_transfer(state, currency, amount, lock_ref) do
    with {:ok, new_state} <- withdraw(state, currency, amount) do
      {:ok, set_lock(new_state, currency, amount, lock_ref)}
    end
  end

  def finish_transfer(state, lock_ref), do: remove_lock_ref(state, lock_ref)

  def cancel_transfer(%__MODULE__{locks: locks} = state, lock_ref) do
    case Map.get(locks, lock_ref) do
      nil ->
        throw({:unreachable, "canceling transfer which doesn't exist"})

      %{currency: currency, amount: amount} ->
        state
        |> deposit(currency, amount)
        |> remove_lock_ref(lock_ref)
    end
  end

  defp remove_lock_ref(%__MODULE__{locks: locks} = state, lock_ref),
    do: %__MODULE__{state | locks: Map.delete(locks, lock_ref)}

  defp set_lock(%__MODULE__{locks: locks} = state, currency, amount, lock_ref) do
    %__MODULE__{state | locks: Map.put(locks, lock_ref, %{currency: currency, amount: amount})}
  end
end
