defmodule Openmft.Partners.Account.Page do
  @moduledoc """
  UI configuration for the Account resource.
  """

  use Openmft.Ui, resource: Openmft.Partners.Account

  form do
    action [:create, :update] do
      field :name, autofocus: true
      field :username
      field :status
      field :company_id, label: "Company"
    end
  end

  data_table do
    action_type :read do
      exclude([:id, :company_id, :company])
      column(:name)
      column(:username)
      column(:status)
    end
  end
end
