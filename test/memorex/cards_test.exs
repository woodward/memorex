defmodule Memorex.CardsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards
  alias Memorex.Scheduler.Config
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, CardLog, Deck, Note}
  alias Timex.Duration

  describe "update_card!" do
    test "updates the card and also the due field, and incrementes the reps field" do
      old_due = ~U[2022-01-01 12:00:00Z]
      card = %Card{due: old_due, interval: Duration.parse!("P1D"), reps: 3}
      card = Repo.insert!(card)
      time_now = ~U[2022-02-01 12:00:00Z]

      updated_card = Cards.update_card!(card, %{interval: Duration.parse!("P10D")}, time_now)

      assert updated_card.due == ~U[2022-02-11 12:00:00Z]
      assert updated_card.interval == Duration.parse!("P10D")
      assert updated_card.reps == 4
    end
  end

  describe "cards_for_deck/1" do
    test "gets the cards associated with a particular deck" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      card1 = Repo.insert!(%Card{note: note1})

      deck2 = Repo.insert!(%Deck{})
      note2 = Repo.insert!(%Note{deck: deck2})
      _card2 = Repo.insert!(%Card{note: note2})

      cards = Cards.cards_for_deck(deck1.id) |> Repo.all()
      assert length(cards) == 1
      [card] = cards
      assert card.id == card1.id
    end

    test "can pass in optional limit option" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1})

      note2 = Repo.insert!(%Note{deck: deck1})
      _card2 = Repo.insert!(%Card{note: note2})

      cards = Cards.cards_for_deck(deck1.id, limit: 1) |> Repo.all()
      assert length(cards) == 1
    end

    @tag :skip
    test "can pass in optional order_by option" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1, note_question_index: 2})

      note2 = Repo.insert!(%Note{deck: deck1})
      _card2 = Repo.insert!(%Card{note: note2, note_question_index: 1})

      cards = Cards.cards_for_deck(deck1.id, order_by: :note_question_index) |> Repo.all()
      assert length(cards) == 2
      [retrieved_card1, retrieved_card2] = cards

      assert retrieved_card1.note_question_index == 1
      assert retrieved_card2.note_question_index == 2
    end
  end

  describe "get_card!/1" do
    test "retrieves the card via the ID and preloads the card logs and the note" do
      deck = %Deck{} |> Repo.insert!()
      note = %Note{content: ["First", "Second"], deck: deck}
      card1 = Repo.insert!(%Card{card_type: :review, note: note})
      _card2 = Repo.insert!(%Card{card_type: :relearn, note: note})

      _card_log_older =
        %CardLog{
          card: card1,
          interval: Duration.parse!("PT1S"),
          last_interval: Duration.parse!("PT1S"),
          time_to_answer: Duration.parse!("PT1S")
        }
        |> Repo.insert!()

      # This timer sleep is super gross, but I don't know how else to get around it (?)
      :timer.sleep(1000)

      _card_log_newer =
        %CardLog{
          card: card1,
          interval: Duration.parse!("PT9S"),
          last_interval: Duration.parse!("PT9S"),
          time_to_answer: Duration.parse!("PT9S")
        }
        |> Repo.insert!()

      retrieved_card1 = Cards.get_card!(card1.id)
      assert retrieved_card1.note.content == ["First", "Second"]
      assert retrieved_card1.note.deck_id == deck.id

      assert retrieved_card1.card_type == :review

      [first_card_log | _rest] = retrieved_card1.card_logs
      assert first_card_log.interval == Duration.parse!("PT9S")
    end
  end

  describe "set_new_cards_in_deck_to_learn_cards" do
    test "works" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      card1 = Repo.insert!(%Card{note: note1, card_type: :review})
      card4 = Repo.insert!(%Card{note: note1, card_type: :relearn})

      note2 = Repo.insert!(%Note{deck: deck1})
      _card2 = Repo.insert!(%Card{note: note2, card_type: :new})
      _card3 = Repo.insert!(%Card{note: note2, card_type: :new})

      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      time_now = ~U[2022-02-01 12:00:00Z]
      Cards.set_new_cards_in_deck_to_learn_cards(deck1.id, config, time_now, limit: 1)

      query = Ecto.Query.from(c in Card, where: c.card_type == :learn)
      learn_cards = Repo.all(query)

      assert length(learn_cards) == 1
      [learn_card] = learn_cards
      assert learn_card.card_type == :learn
      assert learn_card.id != card1.id
      assert learn_card.id != card4.id

      card_logs = Ecto.Query.from(CardLog) |> Repo.all()

      assert length(card_logs) == 1
      [card_log] = card_logs

      assert card_log.answer_choice == nil
      assert card_log.card_type == :learn
      assert card_log.current_step == 0
      assert card_log.due == time_now
      assert card_log.ease_factor == nil
      assert card_log.interval == Duration.parse!("PT1M")
      assert card_log.last_card_type == :new
      assert card_log.last_due == nil
      assert card_log.last_ease_factor == nil
      assert card_log.last_interval == nil
      assert card_log.last_step == nil
      assert card_log.reps == 0
      assert card_log.time_to_answer == nil
    end
  end

  describe "convert_new_card_to_learn_card" do
    test "converts a card from a :new card to a :learn card" do
      card_before = Repo.insert!(%Card{card_type: :new})

      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      time_now = ~U[2022-02-01 12:00:00Z]
      query = Ecto.Query.from(c in Card, where: c.card_type == :learn)
      assert Enum.empty?(Repo.all(query))

      card_after = Cards.convert_new_card_to_learn_card(card_before, config, time_now)

      learn_cards = Repo.all(query)
      assert length(Repo.all(query)) == 1

      [learn_card] = learn_cards
      assert learn_card.id == card_after.id

      assert card_after.card_type == :learn
      assert card_after.due == time_now
      assert card_after.interval == Duration.parse!("PT1M")
      assert card_after.reps == 0

      card_logs = Ecto.Query.from(CardLog) |> Repo.all()

      assert length(card_logs) == 1
      [card_log] = card_logs

      assert card_log.answer_choice == nil
      assert card_log.card_type == :learn
      assert card_log.current_step == 0
      assert card_log.due == time_now
      assert card_log.ease_factor == nil
      assert card_log.interval == Duration.parse!("PT1M")
      assert card_log.last_card_type == :new
      assert card_log.last_due == nil
      assert card_log.last_ease_factor == nil
      assert card_log.last_interval == nil
      assert card_log.last_step == nil
      assert card_log.reps == 0
      assert card_log.time_to_answer == nil
    end
  end

  describe "where_due/2" do
    test "returns the due cards" do
      time_now = ~U[2022-02-01 12:00:00Z]
      due = ~U[2022-02-01 11:59:00Z]
      not_due = ~U[2022-02-01 12:01:00Z]

      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1, content: ["First", "Second"]})
      card1 = Repo.insert!(%Card{note: note1, due: due})
      card2 = Repo.insert!(%Card{note: note1, due: time_now})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      card3 = Repo.insert!(%Card{note: note1_deck2, due: due})
      _card4 = Repo.insert!(%Card{note: note1_deck2, due: not_due})

      note2 = Repo.insert!(%Note{deck: deck1})
      _card5 = Repo.insert!(%Card{note: note2, due: not_due})

      due_cards = from(c in Card) |> Cards.where_due(time_now) |> Repo.all()
      assert length(due_cards) == 3

      ids_of_due_cards = [card1, card2, card3] |> Enum.map(& &1.id)

      [due_card1, due_card2, due_card3] = due_cards

      assert due_card1.id in ids_of_due_cards
      assert due_card2.id in ids_of_due_cards
      assert due_card3.id in ids_of_due_cards
    end
  end

  describe "where_card_type/2" do
    test "returns the cards of a certain type" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1, content: ["First", "Second"]})
      _card1 = Repo.insert!(%Card{note: note1, card_type: :learn})
      card2 = Repo.insert!(%Card{note: note1, card_type: :new})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _card3 = Repo.insert!(%Card{note: note1_deck2, card_type: :review})
      _card4 = Repo.insert!(%Card{note: note1_deck2, card_type: :relearn})

      new_cards = from(c in Card) |> Cards.where_card_type(:new) |> Repo.all()
      assert length(new_cards) == 1
      [new_card] = new_cards
      assert new_card.id == card2.id
    end
  end

  describe "get_one_random_due_card/2" do
    test "returns one random due card for a deck" do
      time_now = ~U[2022-02-01 12:00:00Z]
      due = ~U[2022-02-01 11:59:00Z]
      not_due = ~U[2022-02-01 12:01:00Z]

      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1, content: ["First", "Second"]})
      card1 = Repo.insert!(%Card{note: note1, due: due})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _card1 = Repo.insert!(%Card{note: note1_deck2, due: due})

      note2 = Repo.insert!(%Note{deck: deck1})
      _card2 = Repo.insert!(%Card{note: note2, due: not_due})

      random_due_card = Cards.get_one_random_due_card(deck1.id, time_now)

      assert random_due_card.id == card1.id
      assert random_due_card.note.content == ["First", "Second"]
    end
  end

  describe "due_count/1" do
    test "returns the number of total cards for this deck that are due" do
      time_now = ~U[2022-02-01 12:00:00Z]
      due = ~U[2022-02-01 11:59:00Z]
      not_due = ~U[2022-02-01 12:01:00Z]

      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1, due: due})
      _card2 = Repo.insert!(%Card{note: note1, due: not_due})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _card1 = Repo.insert!(%Card{note: note1_deck2, due: due})

      assert Cards.due_count(deck1.id, time_now) == 1
    end
  end

  describe "count/1" do
    test "returns the number of total cards for this deck" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _card1 = Repo.insert!(%Card{note: note1_deck2})

      assert Cards.count(deck1.id) == 1
    end
  end

  describe "count/2" do
    test "returns the number of cards of a certain type for this deck" do
      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1, card_type: :learn})
      _card2 = Repo.insert!(%Card{note: note1, card_type: :review})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _card1_deck2 = Repo.insert!(%Card{note: note1_deck2})

      assert Cards.count(deck1.id, :review) == 1
    end
  end

  describe "get_interval_choices/2" do
    test "gets the interval choices for this card" do
      card = %Card{card_type: :learn, interval: Duration.parse!("PT1M"), current_step: 0}
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")], graduating_interval_easy: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]
      interval_choices = Cards.get_interval_choices(card, config, unused_time_now)

      assert interval_choices == [
               {:again, Duration.parse!("PT1M")},
               {:hard, Duration.parse!("PT1M")},
               {:good, Duration.parse!("PT10M")},
               {:easy, Duration.parse!("P4D")}
             ]
    end
  end
end
