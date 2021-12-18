defmodule Memorex.CardTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Card, CardLog, Repo}

  test "deletes card logs when deleted" do
    card = Repo.insert!(%Card{})
    card_log = Repo.insert!(%CardLog{card: card})

    Repo.delete!(card)
    assert Repo.get(CardLog, card_log.id) == nil
  end
end
