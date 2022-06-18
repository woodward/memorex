defmodule Memorex.Ecto.Schema do
  @moduledoc """
  This schema enables the Ecto primary keys to be UUIDs by default.
  """

  @type id :: Ecto.UUID.t()

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      # See example `MyApp.Schema` here: https://hexdocs.pm/ecto/Ecto.Schema.html#module-schema-attributes
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime]
    end
  end
end
