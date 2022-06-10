defmodule Memorex.CardLogsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{CardLogs, Repo, TimeUtils}
  alias Memorex.Cards.{Card, CardLog, Deck, Note}
  alias Timex.Duration

  describe "for_day" do
    test "returns the card logs for today" do
      card = %Card{} |> Repo.insert!()
      # start_of_day: ~U[2022-01-01 08:00:00Z]
      # end_of_day:   ~U[2022-01-02 07:59:59Z]

      card_log = create_card_log(card, inserted_at: ~U[2022-01-01 12:00:00Z])
      _card_log_after = create_card_log(card, inserted_at: ~U[2022-01-02 08:01:00Z])
      _card_log_before = create_card_log(card, inserted_at: ~U[2022-01-01 07:59:00Z])
      timezone = "America/Los_Angeles"
      time_now = ~U[2022-01-01 11:00:00Z]

      card_logs = CardLogs.all() |> CardLogs.for_day(time_now, timezone) |> Repo.all()

      assert length(card_logs) == 1
      [retrieved_card_log] = card_logs
      assert retrieved_card_log.id == card_log.id
    end
  end

  describe "where_card_type" do
    test "returns the card logs of a certain type (such as :review) for both card_type and last_card_type" do
      card = %Card{} |> Repo.insert!()
      card_log_review = create_card_log(card, card_type: :review, last_card_type: :review)
      _card_log_review_learn = create_card_log(card, card_type: :review, last_card_type: :learn)
      _card_log_new = create_card_log(card, card_type: :new)
      _card_log_learn = create_card_log(card, card_type: :learn)

      card_logs = CardLogs.all() |> CardLogs.where_card_type(:review) |> Repo.all()

      assert length(card_logs) == 1
      [retrieved_card_log] = card_logs
      assert retrieved_card_log.id == card_log_review.id
    end
  end

  describe "reviews_count_for_day" do
    test "returns the count of the :review card logs for today" do
      deck1 = %Deck{} |> Repo.insert!()
      note1 = %Note{deck: deck1} |> Repo.insert!()
      card1 = %Card{note: note1} |> Repo.insert!()
      # start_of_day: ~U[2022-01-01 08:00:00Z]
      # end_of_day:   ~U[2022-01-02 07:59:59Z]

      _card_log_for_today_for_deck_included =
        create_card_log(card1, inserted_at: ~U[2022-01-01 12:00:00Z], card_type: :review, last_card_type: :review)

      _card_log_for_today_for_deck_excluded =
        create_card_log(card1, inserted_at: ~U[2022-01-01 12:00:00Z], card_type: :review, last_card_type: :learn)

      _card_log_for_today_for_deck_learn = create_card_log(card1, inserted_at: ~U[2022-01-01 12:00:00Z], card_type: :learn)
      _card_log_after = create_card_log(card1, inserted_at: ~U[2022-01-02 08:01:00Z])
      _card_log_before = create_card_log(card1, inserted_at: ~U[2022-01-01 07:59:00Z])

      deck2 = %Deck{} |> Repo.insert!()
      note2 = %Note{deck: deck2} |> Repo.insert!()
      card2 = %Card{note: note2} |> Repo.insert!()
      _card_log_for_today_but_different_deck = create_card_log(card2, inserted_at: ~U[2022-01-01 12:00:00Z])

      timezone = "America/Los_Angeles"
      time_now = ~U[2022-01-01 11:00:00Z]

      count = CardLogs.reviews_count_for_day(deck1.id, time_now, timezone)
      assert count == 1
    end
  end

  describe "count" do
    test "returns the number of card logs" do
      card = %Card{} |> Repo.insert!()
      _card_log1 = create_card_log(card)
      _card_log2 = create_card_log(card)
      _card_log3 = create_card_log(card)

      count = CardLogs.all() |> CardLogs.count()

      assert count == 3
    end
  end

  describe "for_deck" do
    test "returns only the card logs associated with this deck" do
      deck1 = %Deck{} |> Repo.insert!()
      note1 = %Note{deck: deck1} |> Repo.insert!()
      card1 = %Card{note: note1} |> Repo.insert!()
      _card_log1 = create_card_log(card1)

      deck2 = %Deck{} |> Repo.insert!()
      note2 = %Note{deck: deck2} |> Repo.insert!()
      card2 = %Card{note: note2} |> Repo.insert!()
      _card_log2 = create_card_log(card2)

      card_logs = CardLogs.all() |> CardLogs.for_deck(deck1.id) |> Repo.all()

      assert length(card_logs) == 1
    end
  end

  describe "factory function" do
    test "lets you set the inserted_at field" do
      card = %Card{} |> Repo.insert!()
      card_log = create_card_log(card, inserted_at: ~U[2022-01-01 12:00:00Z])
      card_log = Repo.get!(CardLog, card_log.id)
      assert card_log.inserted_at == ~U[2022-01-01 12:00:00Z]
    end

    test "lets you set the card_type field" do
      card = %Card{} |> Repo.insert!()
      card_log = create_card_log(card, card_type: :learn)
      card_log = Repo.get!(CardLog, card_log.id)
      assert card_log.card_type == :learn
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

  def create_card_log(card, opts \\ []) do
    inserted_at = Keyword.get(opts, :inserted_at, Timex.now())
    card_type = Keyword.get(opts, :card_type, :review)
    last_card_type = Keyword.get(opts, :last_card_type, :learn)

    %CardLog{
      answer_choice: :good,
      card_type: card_type,
      due: ~U[2022-01-01 12:00:00Z],
      ease_factor: 2.5,
      interval: Duration.parse!("PT10M"),
      last_card_type: last_card_type,
      last_due: ~U[2022-01-01 12:00:00Z],
      last_ease_factor: 2.4,
      last_interval: Duration.parse!("PT5M"),
      last_step: 2,
      current_step: 1,
      reps: 4,
      time_to_answer: Duration.parse!("PT30S"),
      card: card
    }
    |> Repo.insert!()
    |> Ecto.Changeset.cast(%{inserted_at: inserted_at}, [:inserted_at])
    |> Repo.update!()
  end
end
