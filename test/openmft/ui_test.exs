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

      attribute :internal_notes, :string
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

  defmodule TestProject do
    use Ash.Resource, domain: Openmft.UiTest.TestDomain, data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key :id

      attribute :title, :string do
        public? true
        allow_nil? false
      end
    end

    actions do
      create :create do
        accept [:title]
        argument :note, :string, allow_nil?: false
      end

      update :update do
        accept [:title]
      end

      defaults [:read, :destroy]
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource TestCompany
      resource TestAccount
      resource TestProject
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
        exclude([:id])
        column(:name)
        column(:description)
        column(:status)
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
        exclude([:id, :company_id, :company])
        column(:name)
        column(:username)
        column(:status)
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

    test "detect duplicate field labels" do
      output =
        capture_io(:stderr, fn ->
          defmodule DuplicateFieldLabels do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
                field :description, label: "Name"
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

      assert output =~ "[Openmft.UiTest.DuplicateFieldLabels]"
      assert output =~ "form -> action -> create"
      assert output =~ "2 fields use the label"
    end

    test "detect missing accepted attribute" do
      output =
        capture_io(:stderr, fn ->
          defmodule MissingAccepted do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
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

      assert output =~ "[Openmft.UiTest.MissingAccepted]"
      assert output =~ "form -> action -> create"
      assert output =~ "accepted attribute :description is not a form field"
    end

    test "detect missing argument" do
      output =
        capture_io(:stderr, fn ->
          defmodule MissingArgument do
            use Openmft.Ui, resource: TestProject

            form do
              action :create do
                field :title, autofocus: true
              end

              action :update do
                field :title, autofocus: true
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.MissingArgument]"
      assert output =~ "form -> action -> create"
      assert output =~ "argument :note is not a form field"
    end

    test "detect no autofocus" do
      output =
        capture_io(:stderr, fn ->
          defmodule NoAutofocus do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name
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

      assert output =~ "[Openmft.UiTest.NoAutofocus]"
      assert output =~ "form -> action -> create"
      assert output =~ "exactly one field must have autofocus"
    end

    test "detect multiple autofocus" do
      output =
        capture_io(:stderr, fn ->
          defmodule MultipleAutofocus do
            use Openmft.Ui, resource: TestCompany

            form do
              action :create do
                field :name, autofocus: true
                field :description, autofocus: true
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

      assert output =~ "[Openmft.UiTest.MultipleAutofocus]"
      assert output =~ "form -> action -> create"
      assert output =~ "exactly one field must have autofocus"
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
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
              end

              action :read do
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.DuplicateDataTableActions]"
      assert output =~ "data_table -> action"
      assert output =~ ":read is defined 2 times"
    end

    test "detect duplicate column labels" do
      output =
        capture_io(:stderr, fn ->
          defmodule DuplicateColumnLabels do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                exclude([:id])
                column(:name)
                column(:description, label: "Name")
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.DuplicateColumnLabels]"
      assert output =~ "data_table -> action -> read"
      assert output =~ "2 columns use the label"
    end

    test "detect invalid column source" do
      output =
        capture_io(:stderr, fn ->
          defmodule InvalidColumn do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                exclude([:id, :description])
                column(:name)
                column(:bogus)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.InvalidColumn]"
      assert output =~ "data_table -> action -> read -> columns"
      assert output =~ "does not exist on"
    end

    test "detect private column source" do
      output =
        capture_io(:stderr, fn ->
          defmodule PrivateColumn do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
                column(:notes, source: [:internal_notes])
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.PrivateColumn]"
      assert output =~ "data_table -> action -> read -> columns"
      assert output =~ "is not public on"
    end

    test "detect missing public columns" do
      output =
        capture_io(:stderr, fn ->
          defmodule MissingPublic do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                exclude([:id])
                column(:name)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.MissingPublic]"
      assert output =~ "data_table -> action -> read"
      assert output =~ "public attribute :description is not a defined or excluded column"
    end

    test "detect empty default sort" do
      output =
        capture_io(:stderr, fn ->
          defmodule EmptySort do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                default_sort []
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.EmptySort]"
      assert output =~ "default_sort"
      assert output =~ "must sort on at least one column"
    end

    test "detect empty default display" do
      output =
        capture_io(:stderr, fn ->
          defmodule EmptyDisplay do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                default_display([])
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.EmptyDisplay]"
      assert output =~ "default_display"
      assert output =~ "must display at least one column by default"
    end

    test "detect invalid default display column" do
      output =
        capture_io(:stderr, fn ->
          defmodule InvalidDisplay do
            use Openmft.Ui, resource: TestCompany

            data_table do
              action :read do
                default_display([:name, :bogus])
                exclude([:id])
                column(:name)
                column(:description)
                column(:status)
              end
            end
          end
        end)

      assert output =~ "[Openmft.UiTest.InvalidDisplay]"
      assert output =~ "default_display"
      assert output =~ ":bogus is an undefined or excluded column"
    end
  end
end
