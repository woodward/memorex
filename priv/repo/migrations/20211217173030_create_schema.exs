defmodule Memorex.Repo.Migrations.CreateSchema do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table("decks") do
      add :name, :text

      timestamps()
    end

    create table("notes") do
      add :content, {:array, :text}
      add :in_latest_parse?, :boolean, default: false, null: false

      add :deck_id, references(:decks, on_delete: :delete_all)

      timestamps()
    end

    create table("cards") do
      add :card_queue, :text
      add :card_type, :text
      add :due, :utc_datetime
      add :ease_factor, :float
      add :interval, :integer
      add :lapses, :integer
      add :note_answer_index, :integer
      add :note_question_index, :integer
      add :remaining_steps, :integer
      add :reps, :integer

      add :note_id, references(:notes, on_delete: :delete_all)

      timestamps()
    end

    create table("card_logs") do
      add :answer_choice, :text
      add :card_type, :text
      add :ease_factor, :float, null: false
      add :interval, :integer, null: false
      add :last_interval, :integer, null: false
      add :time_to_answer, :integer, null: false

      add :card_id, references(:cards, on_delete: :delete_all)

      timestamps()
    end
  end
end
