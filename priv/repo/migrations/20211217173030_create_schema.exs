defmodule Memorex.Repo.Migrations.CreateSchema do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table("decks") do
      add :name, :binary

      timestamps()
    end

    create table("notes") do
      add :content, {:array, :binary}
      add :in_latest_parse?, :boolean, default: false, null: false

      add :deck_id, references(:decks, on_delete: :delete_all)

      timestamps()
    end

    create table("cards") do
      add :card_queue, :string
      add :card_type, :string
      add :due, :utc_datetime
      add :note_answer_index, :integer
      add :note_question_index, :integer
      add(:ease_factor, :integer)
      add(:interval, :integer)
      add(:lapses, :integer)
      add(:remaining_steps, :integer)
      add(:reps, :integer)

      add :note_id, references(:notes, on_delete: :delete_all)

      timestamps()
    end

    create table("card_logs") do
      add :answer_choice, :string
      add :card_type, :string
      add(:ease_factor, :integer, null: false)
      add(:interval, :integer, null: false)
      add(:last_interval, :integer, null: false)
      add(:time_to_answer, :integer, null: false)

      add :card_id, references(:cards, on_delete: :delete_all)

      timestamps()
    end
  end
end
