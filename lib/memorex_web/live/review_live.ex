defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, CardReviewer, Config, DeckStats, Repo, TimeUtils}
  alias Memorex.Cards.{Card, Deck}
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

        <%= if @prior_card_log do %>
          <h3> <%= live_patch "Last Card - ID #{@prior_card_log.card_id}", to: Routes.card_show_path(@socket, :show, @prior_card_log.card_id) %> </h3>
          <.live_component module={MemorexWeb.CardLive.CardComponent} id={@prior_card_log.card.id} card={@prior_card_log.card} card_log={@prior_card_log} />
        <% end %>
      </div>
    </div>
    """
  end

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
    card = if card_id, do: Cards.get_card!(card_id), else: Cards.get_one_random_due_card(deck.id, time_now)
    interval_choices = if card, do: Cards.get_interval_choices(card, config)

    {:noreply,
     socket
     |> assign(
       card: card,
       card_id: card_id,
       config: config,
       deck_stats: DeckStats.new(deck.id, time_now),
       deck: deck,
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

    new_card = if card_id, do: card_end_state, else: Cards.get_one_random_due_card(deck.id, end_time)
    interval_choices = if new_card, do: Cards.get_interval_choices(new_card, config)

    Phoenix.PubSub.broadcast_from(Memorex.PubSub, self(), "card:#{new_card.id}", :updated_card)

    {:noreply,
     socket
     |> assign(
       card: new_card,
       deck_stats: DeckStats.new(deck.id, end_time),
       display: :show_question,
       interval_choices: interval_choices,
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
end
