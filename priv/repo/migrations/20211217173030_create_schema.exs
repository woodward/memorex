defmodule Memorex.Ecto.Repo.Migrations.CreateSchema do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table("decks") do
      add :name, :text
      add :config, :map, default: %{}

      timestamps()
    end

    create table("notes") do
      add :bidirectional?, :boolean, default: false, null: false
      add :content, {:array, :text}
      add :in_latest_parse?, :boolean, default: false, null: false
      add :category, :text
      add :image_file_path, :text

      add :deck_id, references(:decks, on_delete: :delete_all)

      timestamps()
    end

    create table("cards") do
      add :card_status, :text
      add :card_type, :text
      add :current_step, :integer
      add :due, :utc_datetime
      add :ease_factor, :float
      add :interval, :integer
      add :interval_prior_to_lapse, :integer
      add :lapses, :integer
      add :note_answer_index, :integer
      add :note_question_index, :integer
      add :reps, :integer

      add :note_id, references(:notes, on_delete: :delete_all)

      timestamps()
    end

    create table("card_logs") do
      add :answer_choice, :text
      add :card_status, :text
      add :card_type, :text
      add :current_step, :integer
      add :due, :utc_datetime
      add :ease_factor, :float
      add :interval, :integer
      add :last_card_status, :text
      add :last_card_type, :text
      add :last_due, :utc_datetime
      add :last_ease_factor, :float
      add :last_interval, :integer
      add :last_step, :integer
      add :reps, :integer
      add :time_to_answer, :integer

      add :card_id, references(:cards, on_delete: :delete_all)

      timestamps()
    end
  end
end
