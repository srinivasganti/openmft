defmodule OpenmftWeb.CompanyLiveTest do
  use OpenmftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Openmft.Partners.Company

  defp create_company(_context) do
    company =
      Company
      |> Ash.Changeset.for_create(:create, %{
        name: "Acme Corp",
        description: "A test company",
        email: "acme@example.com",
        phone_number: "555-0100"
      })
      |> Ash.create!()

    %{company: company}
  end

  describe "Index" do
    test "renders empty table", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/companies")

      assert html =~ "Companies"
      assert html =~ "New Company"
      assert has_element?(view, "table")
    end

    setup [:create_company]

    test "lists companies with default visible columns", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/companies")

      # Default visible: name, email, phone_number, updated_at
      assert html =~ company.name
      assert html =~ "acme@example.com"
      assert html =~ "555-0100"

      # Hidden by default: description, billing_id, modified_by, status
      refute html =~ "A test company"
    end

    test "toggles a column on", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # Description is hidden by default
      refute render(view) =~ "A test company"

      # Toggle description on
      view |> element(~s|input[phx-value-column="description"]|) |> render_click()

      assert render(view) =~ "A test company"
    end

    test "toggles a column off", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # Email is visible by default
      assert render(view) =~ "acme@example.com"

      # Toggle email off
      view |> element(~s|input[phx-value-column="email"]|) |> render_click()

      refute render(view) =~ "acme@example.com"
    end

    test "restores default columns", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # Toggle email off
      view |> element(~s|input[phx-value-column="email"]|) |> render_click()
      refute render(view) =~ "acme@example.com"

      # Restore defaults
      view |> element(~s|button[phx-click="restore-default-columns"]|) |> render_click()
      assert render(view) =~ "acme@example.com"
    end

    test "navigates to new company form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      html =
        view
        |> element(~s|a[href="/companies/new"]|)
        |> render_click()

      assert_patch(view, ~p"/companies/new")
      assert html =~ "New Company"
    end

    test "creates a new company", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies/new")

      view
      |> form("#create-form",
        form: %{name: "New Co", description: "Brand new", email: "new@example.com"}
      )
      |> render_submit()

      assert_patch(view, ~p"/companies")

      html = render(view)
      assert html =~ "New Co"
      assert html =~ "new@example.com"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies/new")

      html =
        view
        |> form("#create-form", form: %{name: ""})
        |> render_change()

      assert html =~ "create-form"
    end

    test "navigates to edit company form", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company.id}/edit")

      html = render(view)
      assert html =~ "Edit #{company.name}"
      assert html =~ company.name
    end

    test "updates a company", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company.id}/edit")

      view
      |> form("#update-form", form: %{name: "Updated Corp"})
      |> render_submit()

      assert_patch(view, ~p"/companies")

      html = render(view)
      assert html =~ "Updated Corp"
    end

    test "shows company detail page", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

      assert html =~ company.name
      assert html =~ "acme@example.com"
      assert html =~ "Accounts"
    end

    test "cannot delete an active company", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # Delete button is disabled for active companies
      assert has_element?(
               view,
               ~s|button[phx-click="delete"][phx-value-id="#{company.id}"][disabled]|
             )
    end

    test "deletes a company after disabling it", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # First disable the company
      view
      |> element(~s|button[phx-click="toggle-status"][phx-value-id="#{company.id}"]|)
      |> render_click()

      # Now delete should work
      view
      |> element(~s|button[phx-click="delete"][phx-value-id="#{company.id}"]|)
      |> render_click()

      html = render(view)
      refute html =~ company.name
    end

    test "toggles company status", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      # Company starts as active — toggle to inactive
      view
      |> element(~s|button[phx-click="toggle-status"][phx-value-id="#{company.id}"]|)
      |> render_click()

      # Should show inactive icon (hero-x-circle)
      assert has_element?(view, ~s|span[class*="hero-x-circle"]|)

      # Toggle back to active
      view
      |> element(~s|button[phx-click="toggle-status"][phx-value-id="#{company.id}"]|)
      |> render_click()

      # Should show active icon (hero-check-circle-solid)
      assert has_element?(view, ~s|span[class*="hero-check-circle-solid"]|)
    end

    test "sorts by column ascending", %{conn: conn} do
      Company
      |> Ash.Changeset.for_create(:create, %{name: "Zebra Corp"})
      |> Ash.create!()

      {:ok, view, _html} = live(conn, ~p"/companies")

      # Default sort is name:asc, Acme should be before Zebra
      html = render(view)
      acme_pos = :binary.match(html, "Acme Corp") |> elem(0)
      zebra_pos = :binary.match(html, "Zebra Corp") |> elem(0)
      assert acme_pos < zebra_pos
    end

    test "sorts descending on second click", %{conn: conn} do
      Company
      |> Ash.Changeset.for_create(:create, %{name: "Zebra Corp"})
      |> Ash.create!()

      {:ok, view, _html} = live(conn, ~p"/companies")

      # Click name to cycle: asc (default) -> desc
      view
      |> element(~s|button[phx-click="sort-column"][phx-value-column="name"]|)
      |> render_click()

      html = render(view)
      acme_pos = :binary.match(html, "Acme Corp") |> elem(0)
      zebra_pos = :binary.match(html, "Zebra Corp") |> elem(0)
      assert zebra_pos < acme_pos
    end

    test "search filters companies", %{conn: conn} do
      Company
      |> Ash.Changeset.for_create(:create, %{name: "Zebra Corp"})
      |> Ash.create!()

      {:ok, view, _html} = live(conn, ~p"/companies")

      view |> form("form[phx-change=search]", %{search_term: "Acme"}) |> render_change()

      html = render(view)
      assert html =~ "Acme Corp"
      refute html =~ "Zebra Corp"
    end

    test "clear search shows all companies", %{conn: conn} do
      Company
      |> Ash.Changeset.for_create(:create, %{name: "Zebra Corp"})
      |> Ash.create!()

      {:ok, view, _html} = live(conn, ~p"/companies")

      view |> form("form[phx-change=search]", %{search_term: "Acme"}) |> render_change()
      refute render(view) =~ "Zebra Corp"

      view |> element(~s|button[phx-click="clear-search"]|) |> render_click()

      html = render(view)
      assert html =~ "Acme Corp"
      assert html =~ "Zebra Corp"
    end
  end
end
