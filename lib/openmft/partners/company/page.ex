defmodule Openmft.Partners.Company.Page do
  @moduledoc """
  UI configuration for the Company resource.
  """

  use Openmft.Ui, resource: Openmft.Partners.Company

  form do
    action [:create, :update] do
      field :name, autofocus: true
      field :description
      field :status
      field :email
      field :phone_number
      field :billing_id
    end
  end

  data_table do
    action_type :read do
      default_display([:name, :email, :phone_number, :updated_at])
      default_sort([{:name, :asc}])
      exclude([:id])
      column(:name)
      column(:email)
      column(:phone_number)
      column(:billing_id)
      column(:modified_by)
      column(:description)
      column(:status)
      column(:updated_at, label: "Last Modified")
    end
  end
end
