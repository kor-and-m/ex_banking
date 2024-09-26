defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking.Utils

  @req_limit Application.compile_env!(:ex_banking, :requests_per_user_limit)

  @user "ExBankingUser"
  @user2 "ExBankingUser2"
  @user3 "ExBankingUser3"

  @user4 "ExBankingUser4"
  @user5 "ExBankingUser5"

  @broken_user "broken_user"

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

    for _i <- 1..@req_limit do
      {:ok, _, _} = ExBanking.send(@user2, @user3, 0.1, @currency)
    end

    transfers_sum = @req_limit * 0.1

    assert(ExBanking.get_balance(@user2, @currency) === {:ok, 4.21 - transfers_sum})
    assert(ExBanking.get_balance(@user3, @currency) === {:ok, 0.79 + transfers_sum})
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

  test "async high load test" do
    assert(ExBanking.create_user(@user4) === :ok)
    assert(ExBanking.create_user(@user5) === :ok)
    assert(ExBanking.deposit(@user4, 5, @currency) === {:ok, 5.0})
    assert(ExBanking.deposit(@user5, 5, @currency) === {:ok, 5.0})
    broken_user_pid = fake_user(@broken_user)

    for _i <- 1..@req_limit do
      assert({:error, :request_timeout} === ExBanking.send(@user4, @broken_user, 0.1, @currency))
    end

    assert(
      {:error, :too_many_requests_to_sender} ===
        ExBanking.send(@user4, @broken_user, 0.1, @currency)
    )

    assert(
      {:error, :too_many_requests_to_receiver} === ExBanking.send(@user5, @user4, 0.1, @currency)
    )

    send(broken_user_pid, :stop)
  end

  defp fake_user(user_name) do
    server_name = user_name |> Utils.user_name_to_server_name() |> String.to_atom()
    fake_process = spawn(&loop/0)
    Process.register(fake_process, server_name)
    fake_process
  end

  defp loop() do
    receive do
      :stop -> :ok
      _ -> loop()
    end
  end
end
