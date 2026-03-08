defmodule BookVisually.Repo do
  use Ecto.Repo,
    otp_app: :bookvisually,
    adapter: Ecto.Adapters.Postgres
end
