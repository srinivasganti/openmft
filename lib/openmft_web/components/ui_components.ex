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
  attr :visible_columns, :list, default: nil
  attr :all_columns, :list, default: nil

  slot :row_action, doc: "per-row action buttons"

  def ui_data_table(assigns) do
    config = Info.data_table_for(assigns.ui, assigns.action)

    display_names =
      if assigns.visible_columns do
        assigns.visible_columns
      else
        config.default_display
      end

    columns = Enum.map(display_names, fn name -> Map.fetch!(config.columns, name) end)
    id = assigns.id || "#{assigns.action}-table"

    all_column_structs =
      if assigns.all_columns do
        Enum.map(assigns.all_columns, fn name -> Map.fetch!(config.columns, name) end)
      else
        nil
      end

    assigns =
      assigns
      |> assign(:config, config)
      |> assign(:columns, columns)
      |> assign(:id, id)
      |> assign(:all_column_structs, all_column_structs)

    ~H"""
    <.column_toggle_dropdown
      :if={@all_column_structs}
      all_columns={@all_column_structs}
      visible_columns={@visible_columns}
    />
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

  attr :all_columns, :list, required: true
  attr :visible_columns, :list, required: true

  defp column_toggle_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end mb-2">
      <div tabindex="0" role="button" class="btn btn-sm btn-outline">
        Show Columns
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-200 rounded-box z-10 w-56 p-2 shadow-sm">
        <li :for={col <- @all_columns}>
          <label class="label cursor-pointer justify-start gap-2">
            <input
              type="checkbox"
              class="checkbox checkbox-sm"
              checked={col.name in @visible_columns}
              phx-click="toggle-column"
              phx-value-column={col.name}
            />
            <span>{col.label}</span>
          </label>
        </li>
        <li class="mt-2 border-t border-base-300 pt-2">
          <button type="button" phx-click="restore-default-columns" class="btn btn-xs btn-ghost">
            Restore Default View
          </button>
        </li>
      </ul>
    </div>
    """
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
  attr :options, :map, default: %{}
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
      <.ui_form_fields fields={@config.fields} form={@form} options={@options} />
      <div class="mt-4 flex justify-end gap-2">
        <.button type="submit" variant="primary">{@config.label}</.button>
      </div>
    </.form>
    """
  end

  @doc false
  attr :fields, :list, required: true
  attr :form, :any, required: true
  attr :options, :map, default: %{}

  def ui_form_fields(assigns) do
    ~H"""
    <div :for={field <- @fields}>
      {render_field(field, @form, @options)}
    </div>
    """
  end

  defp render_field(%Field{type: :select} = field, form, options) do
    merged_options = field.options || Map.get(options, field.name, [])
    assigns = %{field: field, form: form, options: merged_options}

    ~H"""
    <.input
      field={@form[@field.name]}
      label={@field.label}
      type="select"
      options={@options}
      prompt="Select..."
      autofocus={@field.autofocus}
    />
    """
  end

  defp render_field(%Field{} = field, form, _options) do
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

  defp render_field(%FieldGroup{} = group, form, options) do
    assigns = %{group: group, form: form, options: options}

    ~H"""
    <fieldset class={["fieldset", @group.class]}>
      <legend :if={@group.label} class="fieldset-legend">{@group.label}</legend>
      <div :for={field <- @group.fields}>
        {render_field(field, @form, @options)}
      </div>
    </fieldset>
    """
  end

  defp input_type(%Field{type: :long_text}), do: "textarea"
  defp input_type(%Field{type: _}), do: "text"
end
