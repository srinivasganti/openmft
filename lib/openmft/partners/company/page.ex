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
    end
  end

  data_table do
    action_type :read do
      exclude([:id])
      column(:name)
      column(:description)
      column(:status)
    end
  end
end
