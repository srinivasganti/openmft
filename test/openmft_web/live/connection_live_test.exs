defmodule OpenmftWeb.ConnectionLiveTest do
  use OpenmftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Openmft.Partners.{Account, Company, Connection}

  defp create_connection(_context) do
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

    connection =
      Connection
      |> Ash.Changeset.for_create(:create, %{
        name: "Production SFTP",
        protocol: :sftp,
        host: "sftp.acme.com",
        port: 22,
        account_id: account.id
      })
      |> Ash.create!()

    %{company: company, account: account, connection: connection}
  end

  describe "Index" do
    test "renders empty table", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/connections")

      assert html =~ "Connections"
      assert html =~ "New Connection"
      assert has_element?(view, "table")
    end

    setup [:create_connection]

    test "lists connections in data table", %{conn: conn, connection: connection} do
      {:ok, _view, html} = live(conn, ~p"/connections")

      assert html =~ connection.name
      assert html =~ "sftp.acme.com"
    end

    test "navigates to new connection form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/connections")

      html =
        view
        |> element(~s|a[href="/connections/new"]|)
        |> render_click()

      assert_patch(view, ~p"/connections/new")
      assert html =~ "New Connection"
    end

    test "creates a new connection via dropdown selection", %{conn: conn, account: account} do
      {:ok, view, _html} = live(conn, ~p"/connections/new")

      html = render(view)
      assert html =~ "Select..."
      assert html =~ account.name

      view
      |> form("#create-form",
        form: %{
          name: "Backup FTP",
          protocol: "ftps",
          host: "ftp.acme.com",
          port: "990",
          account_id: account.id
        }
      )
      |> render_submit()

      assert_patch(view, ~p"/connections")

      html = render(view)
      assert html =~ "Backup FTP"
    end

    test "navigates to edit connection form", %{conn: conn, connection: connection} do
      {:ok, view, _html} = live(conn, ~p"/connections/#{connection.id}/edit")

      html = render(view)
      assert html =~ "Edit #{connection.name}"
    end

    test "updates a connection", %{conn: conn, connection: connection} do
      {:ok, view, _html} = live(conn, ~p"/connections/#{connection.id}/edit")

      view
      |> form("#update-form", form: %{name: "Updated SFTP"})
      |> render_submit()

      assert_patch(view, ~p"/connections")

      html = render(view)
      assert html =~ "Updated SFTP"
    end

    test "deletes a connection", %{conn: conn, connection: connection} do
      {:ok, view, _html} = live(conn, ~p"/connections")

      view
      |> element(~s|button[phx-click="delete"][phx-value-id="#{connection.id}"]|)
      |> render_click()

      html = render(view)
      refute html =~ connection.name
    end
  end
end
