defmodule OpenmftWeb.CompanyLive.Show do
  use OpenmftWeb, :live_view

  alias Openmft.Partners.Company

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    company = Ash.get!(Company, id, load: [:accounts])

    {:ok,
     socket
     |> assign(:page_title, company.name)
     |> assign(:company, company)}
  end
end
