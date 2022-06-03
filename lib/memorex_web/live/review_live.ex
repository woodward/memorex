defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, Config, Repo}
  alias Memorex.Cards.{Card, Deck}
  alias Timex.Duration

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Deck <%= @deck.name %> </h1>
    <h2> Time to answer: <%= Timex.Format.Duration.Formatters.Humanized.format(@time_to_answer) %> </h2>

    <h3> <%= Card.question(@card) %> </h3>

    <%= if @display == :show_question do %>
      <button phx-click="show-answer"> Answer </button>
    <% end %>

    <%= if @display == :show_question_and_answer do %>
      <h3> <%= Card.answer(@card) %> </h3>
      <button phx-click="rate-difficulty" phx-value-answer_choice="again"> Again </button>
      <button phx-click="rate-difficulty" phx-value-answer_choice="hard"> Hard </button>
      <button phx-click="rate-difficulty" phx-value-answer_choice="good"> Good </button>
      <button phx-click="rate-difficulty" phx-value-answer_choice="easy"> Easy </button>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    config = %Config{}
    time_now = Timex.now()

    {:ok,
     socket
     |> assign(
       config: config,
       display: :show_question,
       start_time: time_now,
       time_to_answer: Duration.parse!("PT0S")
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{config: config, start_time: time_now}} = socket) do
    deck = Repo.get!(Deck, params["deck"])
    Cards.set_new_cards_in_deck_to_learn_cards(deck.id, config, time_now, limit: config.new_cards_per_day)
    card = Cards.get_one_random_due_card(deck.id, time_now)

    {:noreply,
     socket
     |> assign(
       deck: deck,
       card: card
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
        %{assigns: %{deck: deck, start_time: start_time}} = socket
      ) do
    IO.puts("--------------------------")
    IO.inspect(answer_choice, label: "answer_choice")

    end_time = Timex.now()
    card = Cards.get_one_random_due_card(deck.id, end_time)
    time_to_answer = Timex.diff(start_time, end_time, :duration)

    {:noreply, socket |> assign(display: :show_question, card: card, start_time: end_time, time_to_answer: time_to_answer)}
  end
end
