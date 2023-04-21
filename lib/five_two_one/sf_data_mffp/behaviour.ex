defmodule FiveTwoOne.SfDataMffp.Behaviour do
  @callback get_all_facilities() :: {:ok, [FiveTwoOne.SfDataMffp.Facility.t()]} | {:error, any()}
end
