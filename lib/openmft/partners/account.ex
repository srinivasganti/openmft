defmodule Openmft.Partners.Account do
  use Ash.Resource,
    domain: Openmft.Partners,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "accounts"
    repo Openmft.Repo

    references do
      reference :company, on_delete: :delete
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
      description "The account name."
    end

    attribute :username, :string do
      public? true
      description "The login username for this account."
    end

    attribute :status, :atom do
      public? true
      default :active
      constraints one_of: [:active, :disabled]
      description "The account status."
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :company, Openmft.Partners.Company do
      public? true
      allow_nil? false
    end

    has_many :connections, Openmft.Partners.Connection
  end
end
