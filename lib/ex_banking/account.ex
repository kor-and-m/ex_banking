defmodule ExBanking.Account do
  @moduledoc false

  @behaviour GenServer

  alias ExBanking.Utils
  alias ExBanking.Wallet

  @req_limit Application.compile_env!(:ex_banking, :requests_per_user_limit)

  defmodule State do
    @moduledoc false
    defstruct [:user_name, :wallet, :transfer_requests]
  end

  def deposit(user_name, currency, amount), do: call(user_name, :deposit, [currency, amount])
  def withdraw(user_name, currency, amount), do: call(user_name, :withdraw, [currency, amount])

  def transfer(from_user_name, to_user_name, currency, amount),
    do: call(from_user_name, :transfer, [to_user_name, currency, amount])

  def get_balance(user_name, currency), do: call(user_name, :get_balance, [currency])

  def start_link(user_name) when is_binary(user_name) do
    server_name = user_name |> Utils.user_name_to_server_name() |> String.to_atom()
    GenServer.start_link(__MODULE__, user_name, name: server_name)
  end

  @impl GenServer
  def init(user_name) do
    {:ok, %State{user_name: user_name, wallet: Wallet.new(), transfer_requests: %{}}}
  end

  @impl GenServer
  def handle_info(
        {:async_deposit, sender_pid, lock_ref, currency, amount},
        %State{wallet: wallet} = state
      ) do
    if req_limit_exceeded?(state) do
      send(sender_pid, {:async_deposit_confirm, lock_ref, {:error, :too_many_requests}})
      {:noreply, state}
    else
      new_wallet = Wallet.deposit(wallet, currency, amount)

      send(
        sender_pid,
        {:async_deposit_confirm, lock_ref, currency,
         {:ok, Wallet.get_balance(new_wallet, currency)}}
      )

      {:noreply, %State{state | wallet: new_wallet}}
    end
  end

  def handle_info(
        {:async_deposit_confirm, lock_ref, currency, res},
        %State{wallet: wallet, transfer_requests: transfer_requests} = state
      ) do
    from =
      case Map.get(transfer_requests, lock_ref) do
        nil -> throw({:unreachable, "Request not found"})
        from -> from
      end

    new_wallet =
      case res do
        {:error, :too_many_requests} ->
          GenServer.reply(from, {:error, :too_many_requests_to_receiver})
          Wallet.cancel_transfer(wallet, lock_ref)

        {:ok, new_reciver_balance} ->
          GenServer.reply(from, {:ok, Wallet.get_balance(wallet, currency), new_reciver_balance})
          Wallet.finish_transfer(wallet, lock_ref)
      end

    {:noreply,
     %State{
       state
       | wallet: new_wallet,
         transfer_requests: Map.delete(transfer_requests, lock_ref)
     }}
  end

  @impl GenServer
  def handle_call(request, from, state) do
    if req_limit_exceeded?(state) do
      {:error, :too_many_requests}
    else
      process_call(request, from, state)
    end
  end

  defp process_call({:deposit, [currency, amount]}, _from, %State{wallet: wallet} = state) do
    new_wallet = Wallet.deposit(wallet, currency, amount)
    {:reply, {:ok, Wallet.get_balance(new_wallet, currency)}, %State{state | wallet: new_wallet}}
  end

  defp process_call({:withdraw, [currency, amount]}, _from, %State{wallet: wallet} = state) do
    case Wallet.withdraw(wallet, currency, amount) do
      {:ok, new_wallet} ->
        {:reply, {:ok, Wallet.get_balance(new_wallet, currency)},
         %State{state | wallet: new_wallet}}

      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  defp process_call({:get_balance, [currency]}, _from, %State{wallet: wallet} = state) do
    {:reply, {:ok, Wallet.get_balance(wallet, currency)}, state}
  end

  defp process_call(
         {:transfer, [to_user_name, currency, amount]},
         from,
         %State{wallet: wallet, transfer_requests: transfer_requests} = state
       ) do
    lock_ref = make_ref()

    case Wallet.init_transfer(wallet, currency, amount, lock_ref) do
      {:ok, new_wallet} ->
        sender_pid = self()

        server_name =
          to_user_name |> Utils.user_name_to_server_name() |> String.to_existing_atom()

        send(server_name, {:async_deposit, sender_pid, lock_ref, currency, amount})

        {:noreply,
         %State{
           state
           | wallet: new_wallet,
             transfer_requests: Map.put(transfer_requests, lock_ref, from)
         }}

      {:error, _} = err ->
        {:reply, err, state}
    end
  rescue
    _e in ArgumentError -> {:reply, {:error, :receiver_does_not_exist}, state}
  end

  defp process_call(_, _from, state) do
    {:reply, {:error, :bad_request}, state}
  end

  defp req_limit_exceeded?(%State{transfer_requests: transfer_requests}) do
    map_size(transfer_requests) >= @req_limit
  end

  defp call(user_name, method, params) when is_binary(user_name) do
    # Atom should be created in start_link function
    server_name = user_name |> Utils.user_name_to_server_name() |> String.to_existing_atom()
    GenServer.call(server_name, {method, params})
  rescue
    _e in ArgumentError -> {:error, :user_does_not_exist}
  end

  defp call(_, _, _), do: {:error, :wrong_arguments}
end
