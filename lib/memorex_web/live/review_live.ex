defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, CardReviewer, Config, Repo, TimeUtils}
  alias Memorex.Cards.{Card, Deck}
  alias Timex.Duration

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Deck: <%= @deck.name %> </h1>

    <table class="deck-stats">
      <thead>
        <th> Total </th>
        <th> New </th>
        <th> Learn </th>
        <th> Review </th>
        <th> Due </th>
      </thead>
      <tbody>
        <tr>
          <td> <%= @deck_stats.total %> </td>
          <td> <%= @deck_stats.new %> </td>
          <td> <%= @deck_stats.learn %> </td>
          <td> <%= @deck_stats.review %> </td>
          <td> <%= @deck_stats.due %> </td>
        </tr>
      </tbody>
    </table>

    <%= if !@card do %>
      <h3> No cards to review </h3>
    <% else %>

      <h3> <%= Card.question(@card) %> </h3>

      <%= if @display == :show_question do %>
        <button phx-click="show-answer"> Answer </button>
      <% end %>

      <%= if @display == :show_question_and_answer do %>
        <h3> <%= Card.answer(@card) %> </h3>

        <button class="answer-button again" phx-click="rate-difficulty" phx-value-answer_choice="again">
          <span class="answer-choice"> Again </span>
          <span class="answer-interval"> <%= format(@interval_choices[:again])  %> </span>
        </button>

        <button class="answer-button hard" phx-click="rate-difficulty" phx-value-answer_choice="hard">
          <span class="answer-choice"> Hard </span>
          <span class="answer-interval"> <%= format(@interval_choices[:hard])  %> </span>
        </button>

        <button class="answer-button good" phx-click="rate-difficulty" phx-value-answer_choice="good">
          <span class="answer-choice"> Good </span>
          <span class="answer-interval"> <%= format(@interval_choices[:good])  %> </span>
        </button>

        <button class="answer-button easy" phx-click="rate-difficulty" phx-value-answer_choice="easy">
          <span class="answer-choice"> Easy </span>
          <span class="answer-interval"> <%= format(@interval_choices[:easy])  %> </span>
        </button>
      <% end %>
    <% end %>

    <%= if debug_mode?() && @prior_card_starting_state && @prior_card_end_state do %>
      <hr>

      <h3> Last Card </h3>

      <table>
        <tr>
          <td> Question </td>
          <td> <%= Card.question(@prior_card_end_state) %> </td>
        </tr>
        <tr>
          <td> Answer </td>
          <td> <%= Card.answer(@prior_card_end_state) %> </td>
        </tr>
        <tr>
          <td> Answer Choice </td>
          <td> <%= @last_answer_choice %> </td>
        </tr>
        <tr>
          <td> Time to Answer </td>
          <td> <%= format(@time_to_answer) %> </td>
        </tr>
      </table>

      <table>
        <thead>
          <th> </th>
          <th> Start </th>
          <th> End </th>
        </thead>
        <tbody>
          <tr>
            <td> Card Type </td>
            <td> <%= @prior_card_starting_state.card_type %> </td>
            <td> <%= @prior_card_end_state.card_type %> </td>
          </tr>
          <tr>
            <td> Interval </td>
            <td> <%= format(@prior_card_starting_state.interval) %> </td>
            <td> <%= format(@prior_card_end_state.interval) %> </td>
          </tr>
          <tr>
            <td> Due </td>
            <td> <%= format(@prior_card_starting_state.due) %> </td>
            <td> <%= format(@prior_card_end_state.due) %> </td>
          </tr>
        </tbody>
      </table>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    config = %Config{}
    time_now = TimeUtils.now()

    {:ok,
     socket
     |> assign(
       config: config,
       debug?: true,
       display: :show_question,
       start_time: time_now,
       time_to_answer: Duration.parse!("PT0S"),
       last_answer_choice: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{start_time: time_now, config: config}} = socket) do
    deck = Repo.get!(Deck, params["deck"])
    card = Cards.get_one_random_due_card(deck.id, time_now)
    interval_choices = if card, do: Cards.get_interval_choices(card, config)

    {:noreply,
     socket
     |> assign(
       deck: deck,
       card: card,
       prior_card_starting_state: card,
       prior_card_end_state: nil,
       deck_stats: deck_stats(deck.id, time_now),
       interval_choices: interval_choices
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
        %{assigns: %{deck: deck, start_time: start_time, card: card, config: config}} = socket
      ) do
    IO.puts("--------------------------")
    answer_choice = String.to_atom(answer_choice)
    IO.inspect(answer_choice, label: "answer_choice")

    end_time = TimeUtils.now()
    {prior_card_end_state, card_log} = CardReviewer.answer_card_and_create_log_entry(card, answer_choice, start_time, end_time, config)

    new_card = Cards.get_one_random_due_card(deck.id, end_time)
    interval_choices = if new_card, do: Cards.get_interval_choices(new_card, config)

    {:noreply,
     socket
     |> assign(
       display: :show_question,
       card: new_card,
       start_time: end_time,
       time_to_answer: card_log.time_to_answer,
       prior_card_starting_state: new_card,
       prior_card_end_state: prior_card_end_state,
       last_answer_choice: answer_choice,
       deck_stats: deck_stats(deck.id, end_time),
       interval_choices: interval_choices
     )}
  end

  @spec format(Duration.t() | DateTime.t()) :: String.t()
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)

  # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  def format(%DateTime{} = datetime), do: datetime |> TimeUtils.to_timezone() |> Timex.format!("%a, %b %e, %Y, %l:%M %P", :strftime)

  # Move this somewhere else?  Memorex.DeckStats?
  @spec deck_stats(Ecto.UUID.t(), DateTime.t()) :: map()
  def deck_stats(deck_id, time_now) do
    %{
      total: Cards.count(deck_id),
      new: Cards.count(deck_id, :new),
      learn: Cards.count(deck_id, :learn),
      review: Cards.count(deck_id, :review),
      due: Cards.due_count(deck_id, time_now)
    }
  end

  @spec debug_mode?() :: boolean()
  def debug_mode?(), do: Application.get_env(:memorex, MemorexWeb.ReviewLive)[:debug_mode?]
end
