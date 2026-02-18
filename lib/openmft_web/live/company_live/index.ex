defmodule OpenmftWeb.CompanyLive.Index do
  use OpenmftWeb, :live_view

  alias Openmft.Partners
  alias Openmft.Partners.Company

  @ui Company.Page

  @impl true
  def mount(_params, _session, socket) do
    companies = Ash.read!(Company, action: :read)

    {:ok,
     socket
     |> assign(:page_title, "Companies")
     |> assign(:ui, @ui)
     |> assign(:companies, companies)
     |> assign(:company, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      Company
      |> AshPhoenix.Form.for_create(:create, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "New Company")
    |> assign(:form_action, :create)
    |> assign(:form, form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    company = Ash.get!(Company, id)

    form =
      company
      |> AshPhoenix.Form.for_update(:update, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "Edit #{company.name}")
    |> assign(:company, company)
    |> assign(:form_action, :update)
    |> assign(:form, form)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Companies")
    |> assign(:form, nil)
    |> assign(:form_action, nil)
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, _company} ->
        companies = Ash.read!(Company, action: :read)

        {:noreply,
         socket
         |> put_flash(:info, company_saved_message(socket.assigns.form_action))
         |> assign(:companies, companies)
         |> push_patch(to: ~p"/companies")}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    company = Ash.get!(Company, id)
    Ash.destroy!(company)
    companies = Ash.read!(Company, action: :read)

    {:noreply,
     socket
     |> put_flash(:info, "Company deleted")
     |> assign(:companies, companies)}
  end

  defp company_saved_message(:create), do: "Company created"
  defp company_saved_message(:update), do: "Company updated"
end
