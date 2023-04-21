defmodule FiveTwoOne.Repo do
  use Ecto.Repo,
    otp_app: :five_two_one,
    adapter: Ecto.Adapters.Postgres
end
