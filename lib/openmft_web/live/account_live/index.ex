defmodule OpenmftWeb.AccountLive.Index do
  use OpenmftWeb, :live_view

  alias Openmft.Partners
  alias Openmft.Partners.Account
  alias Openmft.Ui.Info

  @ui Account.Page

  @impl true
  def mount(_params, _session, socket) do
    accounts = Ash.read!(Account, action: :read)
    select_options = Info.load_select_options(@ui, :create, domain: Partners)

    {:ok,
     socket
     |> assign(:page_title, "Accounts")
     |> assign(:ui, @ui)
     |> assign(:accounts, accounts)
     |> assign(:select_options, select_options)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      Account
      |> AshPhoenix.Form.for_create(:create, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "New Account")
    |> assign(:form_action, :create)
    |> assign(:form, form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    account = Ash.get!(Account, id)

    form =
      account
      |> AshPhoenix.Form.for_update(:update, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "Edit #{account.name}")
    |> assign(:form_action, :update)
    |> assign(:form, form)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Accounts")
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
      {:ok, _account} ->
        accounts = Ash.read!(Account, action: :read)

        {:noreply,
         socket
         |> put_flash(:info, saved_message(socket.assigns.form_action))
         |> assign(:accounts, accounts)
         |> push_patch(to: ~p"/accounts")}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    account = Ash.get!(Account, id)
    Ash.destroy!(account)
    accounts = Ash.read!(Account, action: :read)

    {:noreply,
     socket
     |> put_flash(:info, "Account deleted")
     |> assign(:accounts, accounts)}
  end

  defp saved_message(:create), do: "Account created"
  defp saved_message(:update), do: "Account updated"
end
