defmodule OpenmftWeb.PageController do
  use OpenmftWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
