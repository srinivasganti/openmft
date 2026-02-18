alias Openmft.Partners.{Company, Account, Connection}

# Get the existing company
[company] = Ash.read!(Company)
IO.puts("Using company: #{company.name} (#{company.id})")

# Create accounts
acct1 =
  Account
  |> Ash.Changeset.for_create(:create, %{
    name: "Production",
    username: "prod_user",
    status: :active,
    company_id: company.id
  })
  |> Ash.create!()

IO.puts("Created account: #{acct1.name}")

acct2 =
  Account
  |> Ash.Changeset.for_create(:create, %{
    name: "Staging",
    username: "staging_user",
    status: :active,
    company_id: company.id
  })
  |> Ash.create!()

IO.puts("Created account: #{acct2.name}")

# Create connections
conn1 =
  Connection
  |> Ash.Changeset.for_create(:create, %{
    name: "Prod SFTP",
    protocol: :sftp,
    host: "sftp.mftlabs.com",
    port: 22,
    enabled: true,
    account_id: acct1.id
  })
  |> Ash.create!()

IO.puts("Created connection: #{conn1.name}")

conn2 =
  Connection
  |> Ash.Changeset.for_create(:create, %{
    name: "Prod FTPS",
    protocol: :ftps,
    host: "ftps.mftlabs.com",
    port: 990,
    enabled: true,
    account_id: acct1.id
  })
  |> Ash.create!()

IO.puts("Created connection: #{conn2.name}")

conn3 =
  Connection
  |> Ash.Changeset.for_create(:create, %{
    name: "Staging AS2",
    protocol: :as2,
    host: "as2.staging.mftlabs.com",
    port: 443,
    enabled: false,
    account_id: acct2.id
  })
  |> Ash.create!()

IO.puts("Created connection: #{conn3.name}")

IO.puts("\nDone! Created 2 accounts and 3 connections.")
