defmodule Memorex.Schema do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      # See example `MyApp.Schema` here: https://hexdocs.pm/ecto/Ecto.Schema.html#module-schema-attributes
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
