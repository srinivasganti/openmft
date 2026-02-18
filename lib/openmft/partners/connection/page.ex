defmodule Openmft.Partners.Connection.Page do
  @moduledoc """
  UI configuration for the Connection resource.
  """

  use Openmft.Ui, resource: Openmft.Partners.Connection

  form do
    action [:create, :update] do
      field :name, autofocus: true
      field :protocol
      field :host
      field :port
      field :enabled
      field :account_id, label: "Account"
    end
  end

  data_table do
    action_type :read do
      exclude([:id, :account_id, :account])
      column(:name)
      column(:protocol)
      column(:host)
      column(:port)
      column(:enabled)
    end
  end
end
