defmodule Openmft.Partners do
  use Ash.Domain

  resources do
    resource Openmft.Partners.Company
    resource Openmft.Partners.Account
    resource Openmft.Partners.Connection
  end
end
