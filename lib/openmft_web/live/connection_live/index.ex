defmodule OpenmftWeb.ConnectionLive.Index do
  use OpenmftWeb, :live_view

  alias Openmft.Partners
  alias Openmft.Partners.Connection

  @ui Connection.Page

  @impl true
  def mount(_params, _session, socket) do
    connections = Ash.read!(Connection, action: :read)

    {:ok,
     socket
     |> assign(:page_title, "Connections")
     |> assign(:ui, @ui)
     |> assign(:connections, connections)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      Connection
      |> AshPhoenix.Form.for_create(:create, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "New Connection")
    |> assign(:form_action, :create)
    |> assign(:form, form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    connection = Ash.get!(Connection, id)

    form =
      connection
      |> AshPhoenix.Form.for_update(:update, domain: Partners)
      |> to_form()

    socket
    |> assign(:page_title, "Edit #{connection.name}")
    |> assign(:form_action, :update)
    |> assign(:form, form)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Connections")
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
      {:ok, _connection} ->
        connections = Ash.read!(Connection, action: :read)

        {:noreply,
         socket
         |> put_flash(:info, saved_message(socket.assigns.form_action))
         |> assign(:connections, connections)
         |> push_patch(to: ~p"/connections")}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    connection = Ash.get!(Connection, id)
    Ash.destroy!(connection)
    connections = Ash.read!(Connection, action: :read)

    {:noreply,
     socket
     |> put_flash(:info, "Connection deleted")
     |> assign(:connections, connections)}
  end

  defp saved_message(:create), do: "Connection created"
  defp saved_message(:update), do: "Connection updated"
end
