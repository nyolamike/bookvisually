defmodule BookVisuallyWeb.Router do
  use BookVisuallyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BookVisuallyWeb do
    pipe_through :api
  end
end
