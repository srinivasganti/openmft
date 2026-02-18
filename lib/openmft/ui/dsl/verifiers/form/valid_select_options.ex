defmodule Openmft.Ui.Dsl.Verifiers.Form.ValidSelectOptions do
  @moduledoc """
  Validates that select fields have proper configuration:
  - A select field must have either `options` or `relationship`, not both
  - A `relationship` must exist on the resource as a belongs_to
  - The `option_label` must be a public attribute on the destination resource
  """

  use Openmft.Dsl.Verifiers

  alias Ash.Resource.Info, as: ResourceInfo
  alias Openmft.Ui.Form.{Action, Field, FieldGroup}

  @impl true
  def verify(dsl) do
    module = Verifier.get_persisted(dsl, :module, nil)
    resource = Verifier.get_persisted(dsl, :resource, nil)

    for %Action{} = action <- Verifier.get_entities(dsl, [:form]) do
      for field <- collect_fields(action.fields) do
        validate_select_field(field, resource, module, action.name)
      end
    end

    :ok
  end

  defp collect_fields(fields) do
    Enum.flat_map(fields, fn
      %Field{type: :select} = field -> [field]
      %FieldGroup{fields: nested} -> collect_fields(nested)
      _ -> []
    end)
  end

  defp validate_select_field(field, resource, module, action_name) do
    has_options = is_list(field.options) and field.options != []
    has_relationship = not is_nil(field.relationship)

    cond do
      has_options and has_relationship ->
        raise DslError.exception(
                module: module,
                path: [:form, :action, action_name],
                message:
                  "select field #{inspect(field.name)} has both options and relationship — use one or the other"
              )

      not has_options and not has_relationship ->
        raise DslError.exception(
                module: module,
                path: [:form, :action, action_name],
                message:
                  "select field #{inspect(field.name)} has neither options nor relationship"
              )

      has_relationship ->
        validate_relationship(field, resource, module, action_name)

      true ->
        :ok
    end
  end

  defp validate_relationship(field, resource, module, action_name) do
    case ResourceInfo.relationship(resource, field.relationship) do
      nil ->
        raise DslError.exception(
                module: module,
                path: [:form, :action, action_name],
                message:
                  "select field #{inspect(field.name)} references relationship #{inspect(field.relationship)} which does not exist on #{inspect(resource)}"
              )

      %Ash.Resource.Relationships.BelongsTo{} = rel ->
        dest = rel.destination

        case ResourceInfo.public_attribute(dest, field.option_label) do
          nil ->
            raise DslError.exception(
                    module: module,
                    path: [:form, :action, action_name],
                    message:
                      "select field #{inspect(field.name)} uses option_label #{inspect(field.option_label)} which is not a public attribute on #{inspect(dest)}"
                  )

          _ ->
            :ok
        end

      _rel ->
        raise DslError.exception(
                module: module,
                path: [:form, :action, action_name],
                message:
                  "select field #{inspect(field.name)} references relationship #{inspect(field.relationship)}, but only belongs_to relationships are supported for select fields"
              )
    end
  end
end
