defmodule MemorexWeb.ReviewLive do
  @moduledoc """
  The main LiveView for drilling/reviewing `Memorex.Domain.Card`s
  """

  use MemorexWeb, :live_view

  alias Memorex.{Cards, CardLogs, DeckStats, TimeUtils}
  alias Memorex.Scheduler.{CardReviewer, Config}
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, Deck, Note}
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    time_now = TimeUtils.now()

    {:ok,
     socket
     |> assign(
       display: :show_question,
       start_time: time_now
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{start_time: time_now}} = socket) do
    deck = Repo.get!(Deck, params["deck"])
    config = Config.default() |> Config.merge(deck.config)
    card_id = params["card_id"]
    learn_ahead_time = Timex.add(time_now, config.learn_ahead_time_interval)
    card = if card_id, do: Cards.get_card!(card_id), else: Cards.get_one_random_due_card(deck.id, learn_ahead_time)

    card =
      case card && card.card_type do
        :new -> Cards.convert_new_card_to_learn_card(card, config, time_now)
        _ -> card
      end

    interval_choices = if card, do: Cards.get_interval_choices(card, config, time_now)
    num_of_reviewed_cards = CardLogs.reviews_count_for_day(deck.id, time_now, config.timezone)

    {:noreply,
     socket
     |> assign(
       card_id: card_id,
       card: card,
       config: config,
       daily_review_limit_reached?: num_of_reviewed_cards > config.max_reviews_per_day,
       deck_stats: DeckStats.new(deck.id, time_now),
       deck: deck,
       num_of_reviewed_cards: num_of_reviewed_cards,
       interval_choices: interval_choices,
       prior_card_log: nil
     )}
  end

  @impl true
  def handle_event("show-answer", _params, socket) do
    {:noreply, socket |> assign(display: :show_question_and_answer)}
  end

  @impl true
  def handle_event(
        "rate-difficulty",
        %{"answer_choice" => answer_choice} = _params,
        %{assigns: %{deck: deck, start_time: start_time, card: card, card_id: card_id, config: config}} = socket
      ) do
    answer_choice = String.to_atom(answer_choice)
    end_time = TimeUtils.now()
    {card_end_state, card_log} = CardReviewer.answer_card_and_create_log_entry(card, answer_choice, start_time, end_time, config)

    learn_ahead_time = Timex.add(end_time, config.learn_ahead_time_interval)
    next_card = if card_id, do: card_end_state, else: Cards.get_one_random_due_card(deck.id, learn_ahead_time)
    interval_choices = if next_card, do: Cards.get_interval_choices(next_card, config, end_time)
    num_of_reviewed_cards = CardLogs.reviews_count_for_day(deck.id, end_time, config.timezone)

    if next_card, do: Phoenix.PubSub.broadcast_from(Memorex.PubSub, self(), "card:#{next_card.id}", :updated_card)
    Phoenix.PubSub.broadcast_from(Memorex.PubSub, self(), "deck:#{deck.id}", {:updated_deck, deck.id})

    {:noreply,
     socket
     |> assign(
       card: next_card,
       daily_review_limit_reached?: num_of_reviewed_cards > config.max_reviews_per_day,
       deck_stats: DeckStats.new(deck.id, end_time),
       display: :show_question,
       interval_choices: interval_choices,
       num_of_reviewed_cards: num_of_reviewed_cards,
       prior_card_log: card_log,
       start_time: end_time
     )}
  end

  @spec show_debug_info(any()) :: any()
  def show_debug_info(js \\ %JS{}) do
    js
    |> JS.add_class("expanded", to: "#debug-info")
    |> JS.remove_class("collapsed", to: "#debug-info")
  end

  @spec hide_debug_info(any()) :: any()
  def hide_debug_info(js \\ %JS{}) do
    js
    |> JS.add_class("collapsed", to: "#debug-info")
    |> JS.remove_class("expanded", to: "#debug-info")
  end

  @spec initially_show_debug_info?() :: String.t()
  def initially_show_debug_info?() do
    if debug_mode?(), do: "expanded", else: "collapsed"
  end

  @spec debug_mode?() :: boolean()
  def debug_mode?(), do: Application.get_env(:memorex, MemorexWeb.ReviewLive)[:debug_mode?]

  @spec note_category(Card.t() | nil) :: nil | String.t()
  defp note_category(nil), do: nil
  defp note_category(%Card{note: %Note{category: nil}}), do: nil
  defp note_category(%Card{note: %Note{category: category}}), do: " - #{category}"
end
