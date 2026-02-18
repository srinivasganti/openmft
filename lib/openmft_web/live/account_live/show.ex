defmodule OpenmftWeb.AccountLive.Show do
  use OpenmftWeb, :live_view

  alias Openmft.Partners.Account

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    account = Ash.get!(Account, id, load: [:company, :connections])

    {:ok,
     socket
     |> assign(:page_title, account.name)
     |> assign(:account, account)}
  end
end
