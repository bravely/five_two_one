defmodule FiveTwoOne.Games.Registry do
  def start_link(_) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [nil]}
    }
  end
end
