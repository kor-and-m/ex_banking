defmodule ExBanking.AccountTest do
  use ExUnit.Case

  alias ExBanking.Account

  test "sync call without user creation test" do
    res = Account.deposit("account_test1", "USD", 1.1)

    assert(res === {:error, :user_does_not_exist})
  end

  test "sync call with wrong data test" do
    {:ok, _pid} = Account.start_link("account_test4")
    res = Account.deposit(122, "USD", 1.1)

    assert(res === {:error, :wrong_arguments})
  end

  test "deposit test" do
    {:ok, _pid} = Account.start_link("account_test2")
    {:ok, res} = Account.deposit("account_test2", "USD", 1.1)

    assert(res === 1.1)
    assert(Account.get_balance("account_test2", "USD") === {:ok, 1.1})
  end

  test "deposit and withdraw test" do
    {:ok, _pid} = Account.start_link("account_test3")
    {:ok, _res} = Account.deposit("account_test3", "USD", 1.1)
    {:ok, res} = Account.withdraw("account_test3", "USD", 0.52)

    assert(res === 0.58)

    res = Account.withdraw("account_test3", "USD", 2.52)

    assert(res === {:error, :not_enough_money})
  end

  test "transfer test" do
    {:ok, _pid} = Account.start_link("account_test5")
    {:ok, _pid} = Account.start_link("account_test6")
    {:ok, _res} = Account.deposit("account_test5", "USD", 1.1)

    {:ok, balance_first, balance_second} =
      Account.transfer("account_test5", "account_test6", "USD", 0.52)

    assert(balance_first === 0.58)
    assert(balance_second === 0.52)
  end

  test "transfer not enough money test" do
    {:ok, _pid} = Account.start_link("account_test7")
    {:ok, _pid} = Account.start_link("account_test8")
    {:ok, _res} = Account.deposit("account_test7", "USD", 1.1)
    res = Account.transfer("account_test7", "account_test8", "USD", 4)

    assert(res === {:error, :not_enough_money})
  end

  test "transfer to not existing user" do
    {:ok, _pid} = Account.start_link("account_test9")
    {:ok, _res} = Account.deposit("account_test9", "USD", 1.1)
    res = Account.transfer("account_test9", "account_test100500", "USD", 0.7)

    assert(res === {:error, :receiver_does_not_exist})
  end

  test "transfer from not existing user" do
    res = Account.transfer("account_test100500", "account_test100500", "USD", 0.7)

    assert(res === {:error, :user_does_not_exist})
  end
end
