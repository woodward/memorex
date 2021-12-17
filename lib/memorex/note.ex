defmodule Memorex.Note do
  @moduledoc false

  use Memorex.Schema

  schema "notes" do
    field :contents, {:array, :binary}

    timestamps()
  end
end
