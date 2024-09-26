defmodule ExBanking.WalletTest do
  use ExUnit.Case

  alias ExBanking.Wallet

  test "deposit withdraw test" do
    {:ok, res} =
      Wallet.new()
      |> Wallet.deposit("USD", 3)
      |> Wallet.withdraw("USD", 1.587)

    assert(Wallet.get_balance(res, "USD") === 1.41)
  end

  test "withdraw bigger than amount test" do
    res =
      Wallet.new()
      |> Wallet.deposit("USD", 2)
      |> Wallet.withdraw("USD", 2.587)

    assert(res === {:error, :not_enough_money})
  end

  test "success transfer test" do
    lock_ref = make_ref()

    {:ok, wallet} =
      Wallet.new()
      |> Wallet.deposit("USD", 2.3)
      |> Wallet.init_transfer("USD", 1.587, lock_ref)

    assert(Wallet.get_balance(wallet, "USD") === 0.71)

    wallet = Wallet.finish_transfer(wallet, lock_ref)

    assert(Wallet.get_balance(wallet, "USD") === 0.71)
  end

  test "cancel transfer test" do
    lock_ref = make_ref()

    {:ok, wallet} =
      Wallet.new()
      |> Wallet.deposit("USD", 2.3)
      |> Wallet.init_transfer("USD", 1.587, lock_ref)

    assert(Wallet.get_balance(wallet, "USD") === 0.71)

    wallet = Wallet.cancel_transfer(wallet, lock_ref)

    assert(Wallet.get_balance(wallet, "USD") === 2.3)
  end
end
