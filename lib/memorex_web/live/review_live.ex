defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, CardReviewer, Config, DeckStats, Repo, TimeUtils}
  alias Memorex.Cards.{Card, Deck}
  alias Timex.Duration
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Deck: <%= @deck.name %> </h1>

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

    <div id="debug-info" class={"debug-info " <> initially_show_debug_info?()}>
      <img class="caret caret-down" src="/images/caret-down.svg" phx-click={hide_debug_info()} />
      <img class="caret caret-right" src="/images/caret-right.svg" phx-click={show_debug_info()} />

      <div class="debug-contents">
        <hr>

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

        <%= if @prior_card_starting_state && @prior_card_end_state do %>
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
                <td> Ease Factor </td>
                <td> <%= ease_factor(@prior_card_starting_state) %> </td>
                <td> <%= ease_factor(@prior_card_end_state) %> </td>
              </tr>
              <tr>
                <td> Due </td>
                <td> <%= format(@prior_card_starting_state.due) %> </td>
                <td> <%= format(@prior_card_end_state.due) %> </td>
              </tr>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
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
       last_answer_choice: nil,
       start_time: time_now,
       time_to_answer: Duration.parse!("PT0S")
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
       card: card,
       deck_stats: DeckStats.new(deck.id, time_now),
       deck: deck,
       interval_choices: interval_choices,
       prior_card_end_state: nil,
       prior_card_starting_state: card
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
    answer_choice = String.to_atom(answer_choice)
    end_time = TimeUtils.now()
    {prior_card_end_state, card_log} = CardReviewer.answer_card_and_create_log_entry(card, answer_choice, start_time, end_time, config)

    new_card = Cards.get_one_random_due_card(deck.id, end_time)
    interval_choices = if new_card, do: Cards.get_interval_choices(new_card, config)

    {:noreply,
     socket
     |> assign(
       card: new_card,
       deck_stats: DeckStats.new(deck.id, end_time),
       display: :show_question,
       interval_choices: interval_choices,
       last_answer_choice: answer_choice,
       prior_card_end_state: prior_card_end_state,
       prior_card_starting_state: new_card,
       start_time: end_time,
       time_to_answer: card_log.time_to_answer
     )}
  end

  @spec format(Duration.t() | DateTime.t()) :: String.t()
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)

  # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  def format(%DateTime{} = datetime), do: datetime |> TimeUtils.to_timezone() |> Timex.format!("%a, %b %e, %Y, %l:%M %P", :strftime)

  @spec ease_factor(Card.t()) :: String.t()
  def ease_factor(%Card{ease_factor: nil}), do: "-"
  def ease_factor(%Card{ease_factor: ease_factor}), do: ease_factor

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
end
