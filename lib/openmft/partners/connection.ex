defmodule Openmft.Partners.Connection do
  use Ash.Resource,
    domain: Openmft.Partners,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "connections"
    repo Openmft.Repo

    references do
      reference :account, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
      description "The connection name."
    end

    attribute :protocol, :atom do
      public? true
      allow_nil? false
      constraints one_of: [:sftp, :ftps, :as2, :https]
      description "The transfer protocol."
    end

    attribute :host, :string do
      public? true
      allow_nil? false
      description "The remote host address."
    end

    attribute :port, :integer do
      public? true
      description "The remote port number."
    end

    attribute :enabled, :boolean do
      public? true
      default true
      description "Whether the connection is enabled."
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :account, Openmft.Partners.Account do
      public? true
      allow_nil? false
    end
  end
end
