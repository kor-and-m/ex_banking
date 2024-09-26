defmodule ExBankingTest do
  use ExUnit.Case

  @user "ExBankingUser"
  @user2 "ExBankingUser2"
  @user3 "ExBankingUser3"
  @currency "USD"

  test "sync test" do
    assert(ExBanking.create_user(@user) === :ok)
    assert(ExBanking.deposit(@user, 2, @currency) === {:ok, 2.0})
    assert(ExBanking.deposit(@user, 1.111, @currency) === {:ok, 3.11})
    assert(ExBanking.withdraw(@user, 0.791, @currency) === {:ok, 2.32})
    assert(ExBanking.get_balance(@user, @currency) === {:ok, 2.32})
  end

  test "async test" do
    assert(ExBanking.create_user(@user2) === :ok)
    assert(ExBanking.create_user(@user3) === :ok)
    assert(ExBanking.deposit(@user2, 5, @currency) === {:ok, 5.0})
    assert(ExBanking.send(@user2, @user3, 0.791, @currency) === {:ok, 4.21, 0.79})
    assert(ExBanking.send(@user2, @user3, 10.791, @currency) === {:error, :not_enough_money})

    for _i <- 1..20 do
      {:ok, _, _} = ExBanking.send(@user2, @user3, 0.1, @currency)
    end

    assert(ExBanking.get_balance(@user2, @currency) === {:ok, 2.21})
    assert(ExBanking.get_balance(@user3, @currency) === {:ok, 2.79})
  end

  test "sender doesn't exist test" do
    assert(
      ExBanking.send("fakeuser", "fakeuser", 0.791, @currency) ===
        {:error, :sender_does_not_exist}
    )
  end

  test "wrong arguments test" do
    assert(ExBanking.send(1, "fakeuser", 0.791, @currency) === {:error, :wrong_arguments})
    assert(ExBanking.send("fakeuser", :a, 0.791, @currency) === {:error, :wrong_arguments})

    assert(
      ExBanking.send("fakeuser", "fakeuser", "133", @currency) === {:error, :wrong_arguments}
    )

    assert(ExBanking.send("fakeuser", "fakeuser", 0.791, 21) === {:error, :wrong_arguments})
  end
end
