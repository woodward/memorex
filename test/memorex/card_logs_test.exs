defmodule Memorex.CardLogsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{CardLogs, Repo, TimeUtils}
  alias Memorex.Cards.{Card, CardLog, Deck, Note}
  alias Timex.Duration

  describe "count_for_today" do
    test "returns the number of cards reviewed today for certain decks" do
      deck = %Deck{} |> Repo.insert!()
      note = %Note{deck: deck} |> Repo.insert!()
      card = %Card{note: note} |> Repo.insert!()
      _card_log = create_card_log(card, ~U[2022-01-01 12:00:00Z])
      timezone = "America/Los_Angeles"
      time_now = ~U[2022-01-01 12:00:00Z]

      count = CardLogs.count_for_today(deck.id, time_now, timezone)

      assert count == 1
    end
  end

  describe "factory function" do
    test "lets you set the inserted_at field" do
      card = %Card{} |> Repo.insert!()
      card_log = create_card_log(card, ~U[2022-01-01 12:00:00Z])
      card_log = Repo.get!(CardLog, card_log.id)
      assert card_log.inserted_at == ~U[2022-01-01 12:00:00Z]
    end
  end

  describe "explore how Timex functions work" do
    test "end_of_day and beginning_of_day" do
      timezone = "America/Los_Angeles"
      random_time_somewhere_in_middle_of_day = ~U[2022-01-01 12:00:00Z]
      today_pst = random_time_somewhere_in_middle_of_day |> TimeUtils.to_timezone(timezone)
      utc = "Etc/UTC"

      end_of_day = Timex.end_of_day(today_pst)
      assert end_of_day |> TimeUtils.to_timezone(utc) == ~U[2022-01-02 07:59:59Z]

      start_of_day = Timex.beginning_of_day(today_pst)
      assert start_of_day |> TimeUtils.to_timezone(utc) == ~U[2022-01-01 08:00:00Z]
    end
  end

  def create_card_log(card, inserted_at) do
    %CardLog{
      answer_choice: :good,
      card_type: :review,
      due: ~U[2022-01-01 12:00:00Z],
      ease_factor: 2.5,
      interval: Duration.parse!("PT10M"),
      last_card_type: :learn,
      last_due: ~U[2022-01-01 12:00:00Z],
      last_ease_factor: 2.4,
      last_interval: Duration.parse!("PT5M"),
      last_remaining_steps: 2,
      remaining_steps: 1,
      reps: 4,
      time_to_answer: Duration.parse!("PT30S"),
      card: card
    }
    |> Repo.insert!()
    |> Ecto.Changeset.cast(%{inserted_at: inserted_at}, [:inserted_at])
    |> Repo.update!()
  end
end
