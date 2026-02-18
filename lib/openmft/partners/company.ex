defmodule Openmft.Partners.Company do
  use Ash.Resource,
    domain: Openmft.Partners,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "companies"
    repo Openmft.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
      description "The company name."
    end

    attribute :description, :string do
      public? true
      description "A description of the company."
    end

    attribute :status, :atom do
      public? true
      default :active
      constraints one_of: [:active, :inactive, :suspended]
      description "The company status."
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :accounts, Openmft.Partners.Account
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end
end
