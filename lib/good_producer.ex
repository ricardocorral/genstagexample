defmodule GoodProducer do
  use GenStage
  require Logger


  def start_link do
    start_args = :dont_care
    GenStage.start_link(__MODULE__, start_args, name: __MODULE__)
  end


  def init(_start_args) do
    initial_state = %SimpleDemandBuffer{}
    {:producer, initial_state}
  end


  def notify(events) do
    GenStage.call(__MODULE__, {:notify, events})
  end


  def handle_call({:notify, events}, _from, state) do
    {:reply, :ok, events, state}
  end


  def handle_call({:notify, new_events}, _from, buffer) do
    buffer = SimpleDemandBuffer.add_events(buffer, new_events)

    case SimpleDemandBuffer.get_pending_demand(buffer) do
      {:ok, buffer, []} -> {:reply, :ok, [], buffer}
      {events, buffer} -> {:reply, :ok, events, buffer}
    end
    
  end


  def handle_demand(demand, buffer) do
    Logger.debug("#{__MODULE__} incoming demand: #{demand}")
    buffer = SimpleDemandBuffer.register_demand(buffer, demand)


    case SimpleDemandBuffer.get_pending_demand(buffer) do
      {:ok, buffer, []} -> {:noreply, [], buffer}
      {events, buffer} -> {:noreply, events, buffer}
    end
  end
end
