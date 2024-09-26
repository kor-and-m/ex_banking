defmodule ExBanking.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  alias ExBanking.Account

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(name) do
    spec = %{
      id: Account,
      start: {Account, :start_link, [name]}
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: []
    )
  end
end
