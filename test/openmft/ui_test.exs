defmodule Openmft.UiTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  # --- ETS-backed test resources (no DB needed) ---

  defmodule TestCompany do
    use Ash.Resource, domain: Openmft.UiTest.TestDomain, data_layer: Ash.DataLayer.Ets

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
        constraints one_of: [:active, :inactive]
      end
    end

    relationships do
      has_many :accounts, Openmft.UiTest.TestAccount
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end
  end

  defmodule TestAccount do
    use Ash.Resource, domain: Openmft.UiTest.TestDomain, data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key :id

      attribute :name, :string do
        public? true
        allow_nil? false
        description "The account name."
      end

      attribute :username, :string do
        public? true
        description "The login username."
      end

      attribute :status, :atom do
        public? true
        default :active
        constraints one_of: [:active, :disabled]
      end
    end

    relationships do
      belongs_to :company, Openmft.UiTest.TestCompany do
        public? true
        allow_nil? false
      end
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource TestCompany
      resource TestAccount
    end
  end

  # --- Happy path UI module ---

  defmodule CompanyPage do
    use Openmft.Ui, resource: TestCompany

    form do
      action :create do
        field :name, autofocus: true
        field :description
        field :status
      end

      action :update do
        field :name, autofocus: true
        field :description
        field :status
      end
    end

    data_table do
      action_type :read do
        exclude [:id]
        column :name
        column :description
        column :status
      end
    end
  end

  defmodule AccountPage do
    use Openmft.Ui, resource: TestAccount

    form do
      action :create do
        field :name, autofocus: true
        field :username
        field :status
        field :company_id, label: "Company"
      end

      action_type :update do
        field :name, autofocus: true
        field :username
        field :status
        field :company_id, label: "Company"
      end
    end

    data_table do
      action :read do
        exclude [:id, :company_id, :company]
        column :name
        column :username
        column :status
      end
    end
  end

  # --- Happy path tests ---

  describe "resource persistence" do
    test "persisted resource reference works" do
      assert TestCompany == CompanyPage.persisted(:resource, nil)
      assert TestAccount == AccountPage.persisted(:resource, nil)
    end
  end

  describe "form pipeline" do
    test "form fields have correct auto-generated labels" do
      form = Openmft.Ui.Info.form_for(CompanyPage, :create)
      labels = Enum.map(form.fields, & &1.label)

      assert labels == ["Name", "Description", "Status"]
    end

    test "explicit action overrides action_type" do
      # AccountPage has explicit :create and action_type :update
      # The :update action should inherit from action_type
      create_form = Openmft.Ui.Info.form_for(AccountPage, :create)
      update_form = Openmft.Ui.Info.form_for(AccountPage, :update)

      # Both should exist
      assert create_form != nil
      assert update_form != nil

      # Both should have the same field labels since action_type :update
      # expands to :update action with same config
      create_labels = Enum.map(create_form.fields, & &1.label)
      update_labels = Enum.map(update_form.fields, & &1.label)

      assert create_labels == ["Name", "Username", "Status", "Company"]
      assert update_labels == ["Name", "Username", "Status", "Company"]
    end

    test "form labels default from name" do
      form = Openmft.Ui.Info.form_for(CompanyPage, :create)
      assert form.label == "Create"
    end
  end

  describe "data table pipeline" do
    test "data table persisted lookup works" do
      dt = Openmft.Ui.Info.data_table_for(CompanyPage, :read)

      assert dt != nil
      assert dt.name == :read
      assert dt.label == "Read"
    end

    test "data table columns are merged into map" do
      dt = Openmft.Ui.Info.data_table_for(CompanyPage, :read)

      assert is_map(dt.columns)
      assert Map.has_key?(dt.columns, :name)
      assert Map.has_key?(dt.columns, :description)
      assert Map.has_key?(dt.columns, :status)
    end

    test "data table column labels are auto-generated" do
      dt = Openmft.Ui.Info.data_table_for(CompanyPage, :read)

      assert dt.columns[:name].label == "Name"
      assert dt.columns[:description].label == "Description"
      assert dt.columns[:status].label == "Status"
    end

    test "action_type expands to all matching read actions" do
      # CompanyPage uses action_type :read, which should expand to the :read action
      dt = Openmft.Ui.Info.data_table_for(CompanyPage, :read)
      assert dt != nil
    end

    test "default_display defaults to all columns" do
      dt = Openmft.Ui.Info.data_table_for(CompanyPage, :read)
      assert dt.default_display == [:name, :description, :status]
    end
  end

  # --- Verifier tests ---

  describe "form verifiers" do
    test "detect duplicate actions" do
      output =
        capture_io(:stderr, fn ->
          defmodule DuplicateFormActions do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
                field :description
                field :status
              end

              action :create do
                field :name, autofocus: true
                field :description
                field :status
              end

              action :update do
                field :name, autofocus: true
                field :description
                field :status
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.DuplicateFormActions]"
      assert output =~ "form -> action"
      assert output =~ ":create is defined 2 times"
    end

    test "detect invalid fields" do
      output =
        capture_io(:stderr, fn ->
          defmodule InvalidFormField do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
                field :description
                field :status
                field :not_real
              end

              action :update do
                field :name, autofocus: true
                field :description
                field :status
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.InvalidFormField]"
      assert output =~ "form -> action -> create"
      assert output =~ "field :not_real is not an accepted attribute or argument for this action"
    end

    test "detect duplicate fields" do
      output =
        capture_io(:stderr, fn ->
          defmodule DuplicateFormFields do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
                field :description
                field :description, label: "Desc 2"
                field :status
              end

              action :update do
                field :name, autofocus: true
                field :description
                field :status
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.DuplicateFormFields]"
      assert output =~ "form -> action -> create"
      assert output =~ "2 fields define :description"
    end
  end

  describe "data table verifiers" do
    test "detect duplicate data table actions" do
      output =
        capture_io(:stderr, fn ->
          defmodule DuplicateDataTableActions do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                exclude [:id]
                column :name
                column :description
                column :status
              end

              action :read do
                exclude [:id]
                column :name
                column :description
                column :status
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.DuplicateDataTableActions]"
      assert output =~ "data_table -> action"
      assert output =~ ":read is defined 2 times"
    end
  end
end
