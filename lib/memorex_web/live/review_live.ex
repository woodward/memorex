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

    <%= if debug_mode?() do %>
      <hr>

      <h3> Last Card </h3>

      <table>
        <tr>
          <td> Question </td>
          <td> <%= Card.question(@prior_card_at_end) %> </td>
        </tr>
        <tr>
          <td> Answer </td>
          <td> <%= Card.answer(@prior_card_at_end) %> </td>
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
            <td> <%= @prior_card_at_start.card_type %> </td>
            <td> <%= @prior_card_at_end.card_type %> </td>
          </tr>
          <tr>
            <td> Interval </td>
            <td> <%= format(@prior_card_at_start.interval) %> </td>
            <td> <%= format(@prior_card_at_end.interval) %> </td>
          </tr>
          <tr>
            <td> Due </td>
            <td> <%= format(@prior_card_at_start.due) %> </td>
            <td> <%= format(@prior_card_at_end.due) %> </td>
          </tr>
        </tbody>
      </table>
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
       debug?: true,
       display: :show_question,
       start_time: time_now,
       time_to_answer: Duration.parse!("PT0S"),
       last_answer_choice: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{start_time: time_now}} = socket) do
    deck = Repo.get!(Deck, params["deck"])
    card = Cards.get_one_random_due_card(deck.id, time_now)

    {:noreply,
     socket
     |> assign(
       deck: deck,
       card: card,
       prior_card_at_start: card,
       prior_card_at_end: card
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
        %{assigns: %{deck: deck, start_time: start_time, card: card}} = socket
      ) do
    IO.puts("--------------------------")
    answer_choice = String.to_atom(answer_choice)
    IO.inspect(answer_choice, label: "answer_choice")
    prior_card_at_end = card

    end_time = Timex.now()
    new_card = Cards.get_one_random_due_card(deck.id, end_time)
    time_to_answer = Timex.diff(start_time, end_time, :duration)

    {:noreply,
     socket
     |> assign(
       display: :show_question,
       card: new_card,
       start_time: end_time,
       time_to_answer: time_to_answer,
       prior_card_at_start: new_card,
       prior_card_at_end: prior_card_at_end,
       last_answer_choice: answer_choice
     )}
  end

  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)
  def format(%DateTime{} = datetime), do: inspect(datetime)
  # def format(%DateTime{} = datetime), do: Timex.Format.DateTime.Formatters.Humanized.format(datetime)

  def debug_mode?(), do: Application.get_env(:memorex, MemorexWeb.ReviewLive)[:debug_mode?]
end
