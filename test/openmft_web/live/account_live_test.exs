defmodule OpenmftWeb.AccountLiveTest do
  use OpenmftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Openmft.Partners.{Account, Company}

  defp create_account(_context) do
    company =
      Company
      |> Ash.Changeset.for_create(:create, %{name: "Acme Corp"})
      |> Ash.create!()

    account =
      Account
      |> Ash.Changeset.for_create(:create, %{
        name: "Main Account",
        username: "acme_main",
        company_id: company.id
      })
      |> Ash.create!()

    %{company: company, account: account}
  end

  describe "Index" do
    test "renders empty table", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/accounts")

      assert html =~ "Accounts"
      assert html =~ "New Account"
      assert has_element?(view, "table")
    end

    setup [:create_account]

    test "lists accounts in data table", %{conn: conn, account: account} do
      {:ok, _view, html} = live(conn, ~p"/accounts")

      assert html =~ account.name
      assert html =~ "acme_main"
    end

    test "navigates to new account form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      html =
        view
        |> element(~s|a[href="/accounts/new"]|)
        |> render_click()

      assert_patch(view, ~p"/accounts/new")
      assert html =~ "New Account"
    end

    test "creates a new account via dropdown selection", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/accounts/new")

      html = render(view)
      assert html =~ "Select..."
      assert html =~ company.name

      view
      |> form("#create-form",
        form: %{name: "New Acct", username: "new_user", company_id: company.id}
      )
      |> render_submit()

      assert_patch(view, ~p"/accounts")

      html = render(view)
      assert html =~ "New Acct"
    end

    test "navigates to edit account form", %{conn: conn, account: account} do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{account.id}/edit")

      html = render(view)
      assert html =~ "Edit #{account.name}"
    end

    test "updates an account", %{conn: conn, account: account} do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{account.id}/edit")

      view
      |> form("#update-form", form: %{name: "Updated Account"})
      |> render_submit()

      assert_patch(view, ~p"/accounts")

      html = render(view)
      assert html =~ "Updated Account"
    end

    test "deletes an account", %{conn: conn, account: account} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      view
      |> element(~s|button[phx-click="delete"][phx-value-id="#{account.id}"]|)
      |> render_click()

      html = render(view)
      refute html =~ account.name
    end
  end
end
