defmodule OpenmftWeb.UiComponents do
  @moduledoc """
  Reusable components that render UI from `Openmft.Ui` DSL configuration.
  """

  use Phoenix.Component

  import OpenmftWeb.CoreComponents

  alias Openmft.Ui.Form.{Field, FieldGroup}
  alias Openmft.Ui.Info

  # ---------------------------------------------------------------------------
  # Data Table
  # ---------------------------------------------------------------------------

  @doc """
  Renders a data table driven by `Openmft.Ui` DSL configuration.

  ## Assigns

    * `ui` - The UI page module (e.g. `Company.Page`)
    * `action` - The action name atom (e.g. `:read`)
    * `rows` - The list of data records
    * `id` - HTML id for the table body (defaults to `"{action}-table"`)
    * `row_click` - Optional `fn row -> JS command` for row clicks

  ## Slots

    * `:action` - Per-row action buttons, receives the row as `:let`
  """
  attr :ui, :atom, required: true
  attr :action, :atom, required: true
  attr :rows, :list, required: true
  attr :id, :string, default: nil
  attr :row_click, :any, default: nil

  slot :row_action, doc: "per-row action buttons"

  def ui_data_table(assigns) do
    config = Info.data_table_for(assigns.ui, assigns.action)
    columns = display_columns(config)
    id = assigns.id || "#{assigns.action}-table"

    assigns =
      assigns
      |> assign(:config, config)
      |> assign(:columns, columns)
      |> assign(:id, id)

    ~H"""
    <table class={["table table-zebra", @config.class]}>
      <thead>
        <tr>
          <th :for={col <- @columns}>{col.label}</th>
          <th :if={@row_action != []}>
            <span class="sr-only">Actions</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id}>
        <tr
          :for={row <- @rows}
          id={"#{@id}-#{row.id}"}
          phx-click={@row_click && @row_click.(row)}
          class={@row_click && "hover:cursor-pointer"}
        >
          <td :for={col <- @columns}>
            {resolve_column_value(row, col)}
          </td>
          <td :if={@row_action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              {render_slot(@row_action, row)}
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp display_columns(config) do
    config.default_display
    |> Enum.map(fn name -> Map.fetch!(config.columns, name) end)
  end

  defp resolve_column_value(row, column) do
    Enum.reduce(column.source, row, fn key, acc ->
      case acc do
        %{} -> Map.get(acc, key)
        _ -> nil
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Form
  # ---------------------------------------------------------------------------

  @doc """
  Renders a form driven by `Openmft.Ui` DSL configuration.

  Uses `AshPhoenix.Form` for change tracking and validation.

  ## Assigns

    * `ui` - The UI page module
    * `action` - The action name atom
    * `form` - An `AshPhoenix.Form` (wrapped with `to_form/1`)
    * `id` - HTML id for the form (defaults to `"{action}-form"`)
    * `on_submit` - The phx-submit event name (default: `"save"`)
    * `on_validate` - The phx-change event name (default: `"validate"`)
  """
  attr :ui, :atom, required: true
  attr :action, :atom, required: true
  attr :form, :any, required: true
  attr :id, :string, default: nil
  attr :on_submit, :string, default: "save"
  attr :on_validate, :string, default: "validate"

  def ui_form(assigns) do
    config = Info.form_for(assigns.ui, assigns.action)
    id = assigns.id || "#{assigns.action}-form"

    assigns =
      assigns
      |> assign(:config, config)
      |> assign(:id, id)

    ~H"""
    <.form
      for={@form}
      id={@id}
      phx-change={@on_validate}
      phx-submit={@on_submit}
      class={@config.class}
    >
      <.ui_form_fields fields={@config.fields} form={@form} />
      <div class="mt-4 flex justify-end gap-2">
        <.button type="submit" variant="primary">{@config.label}</.button>
      </div>
    </.form>
    """
  end

  @doc false
  attr :fields, :list, required: true
  attr :form, :any, required: true

  def ui_form_fields(assigns) do
    ~H"""
    <div :for={field <- @fields}>
      {render_field(field, @form)}
    </div>
    """
  end

  defp render_field(%Field{} = field, form) do
    assigns = %{field: field, form: form}

    ~H"""
    <.input
      field={@form[@field.name]}
      label={@field.label}
      type={input_type(@field)}
      autofocus={@field.autofocus}
    />
    """
  end

  defp render_field(%FieldGroup{} = group, form) do
    assigns = %{group: group, form: form}

    ~H"""
    <fieldset class={["fieldset", @group.class]}>
      <legend :if={@group.label} class="fieldset-legend">{@group.label}</legend>
      <div :for={field <- @group.fields}>
        {render_field(field, @form)}
      </div>
    </fieldset>
    """
  end

  defp input_type(%Field{type: :long_text}), do: "textarea"
  defp input_type(%Field{type: :select}), do: "select"
  defp input_type(%Field{type: _}), do: "text"
end
