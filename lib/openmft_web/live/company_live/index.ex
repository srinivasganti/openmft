defmodule OpenmftWeb.CompanyLive.Index do
  use OpenmftWeb, :live_view

  alias Openmft.Partners
  alias Openmft.Partners.Company
  alias Openmft.Ui.Info
  alias OpenmftWeb.ColumnToggle
  alias OpenmftWeb.DataTableState

  @ui Company.Page

  @impl true
  def mount(_params, _session, socket) do
    column_assigns = ColumnToggle.init(@ui, :read)
    data_table_assigns = DataTableState.init(@ui, :read, Company)
    companies = load_companies(data_table_assigns)

    {:ok,
     socket
     |> assign(:page_title, "Companies")
     |> assign(:ui, @ui)
     |> assign(:companies, companies)
     |> assign(:company, nil)
     |> assign(column_assigns)
     |> assign(data_table_assigns)}
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
        {:noreply,
         socket
         |> put_flash(:info, company_saved_message(socket.assigns.form_action))
         |> assign(:companies, load_companies(socket))
         |> push_patch(to: ~p"/companies")}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  @impl true
  def handle_event("toggle-status", %{"id" => id}, socket) do
    company = Ash.get!(Company, id)
    new_status = if company.status == :active, do: :inactive, else: :active

    company
    |> Ash.Changeset.for_update(:update, %{status: new_status}, domain: Partners)
    |> Ash.update!()

    {:noreply,
     socket
     |> put_flash(:info, "Company #{new_status}")
     |> assign(:companies, load_companies(socket))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    company = Ash.get!(Company, id)

    if company.status == :active do
      {:noreply, put_flash(socket, :error, "Disable the company before deleting")}
    else
      Ash.destroy!(company)

      {:noreply,
       socket
       |> put_flash(:info, "Company deleted")
       |> assign(:companies, load_companies(socket))}
    end
  end

  @impl true
  def handle_event("toggle-column", %{"column" => column}, socket) do
    column = String.to_existing_atom(column)

    visible =
      ColumnToggle.toggle(
        socket.assigns.visible_columns,
        socket.assigns.all_columns,
        column
      )

    {:noreply, assign(socket, :visible_columns, visible)}
  end

  @impl true
  def handle_event("restore-default-columns", _params, socket) do
    visible = ColumnToggle.restore_defaults(@ui, :read)
    {:noreply, assign(socket, :visible_columns, visible)}
  end

  @impl true
  def handle_event("sort-column", %{"column" => column}, socket) do
    column = String.to_existing_atom(column)
    config = Info.data_table_for(@ui, :read)
    sort = DataTableState.cycle_sort(socket.assigns.sort, column, config.columns)

    socket = assign(socket, :sort, sort)

    {:noreply, assign(socket, :companies, load_companies(socket))}
  end

  @impl true
  def handle_event("search", %{"search_term" => term}, socket) do
    socket = assign(socket, :search_term, term)
    {:noreply, assign(socket, :companies, load_companies(socket))}
  end

  @impl true
  def handle_event("clear-search", _params, socket) do
    socket = assign(socket, :search_term, "")
    {:noreply, assign(socket, :companies, load_companies(socket))}
  end

  defp load_companies(%Phoenix.LiveView.Socket{} = socket) do
    load_companies(
      sort: socket.assigns.sort,
      search_term: socket.assigns.search_term,
      searchable_columns: socket.assigns.searchable_columns,
      action: :read
    )
  end

  defp load_companies(opts) when is_list(opts) do
    DataTableState.build_query(Company, opts) |> Ash.read!()
  end

  defp company_saved_message(:create), do: "Company created"
  defp company_saved_message(:update), do: "Company updated"
end
