defmodule Memorex.Cards.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.{Config, Schema}
  alias Memorex.Cards.Note

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          name: String.t(),
          config: map(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "decks" do
    field :name, :binary
    field :config, :map

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end

  @spec config(t(), Config.t()) :: Config.t()
  def config(deck, default_config) do
    Map.merge(default_config, atomize_keys(deck.config))
  end

  @spec atomize_keys(map()) :: map()
  def atomize_keys(map), do: map |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)
end
