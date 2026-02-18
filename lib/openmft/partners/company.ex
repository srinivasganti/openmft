defmodule Openmft.Partners.Company do
  use Ash.Resource,
    domain: Openmft.Partners,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "companies"
    repo Openmft.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :description, :status, :email, :phone_number, :billing_id]
    end

    update :update do
      accept [:name, :description, :status, :email, :phone_number, :billing_id]
    end
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

    attribute :email, :string do
      public? true
      description "The company contact email."
    end

    attribute :phone_number, :string do
      public? true
      description "The company phone number."
    end

    attribute :billing_id, :string do
      public? true
      description "The company billing identifier."
    end

    attribute :modified_by, :string do
      public? true
      description "The user who last modified this record."
    end

    create_timestamp :inserted_at

    update_timestamp :updated_at do
      public? true
    end
  end

  relationships do
    has_many :accounts, Openmft.Partners.Account
  end
end
