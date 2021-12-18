defmodule Memorex.Repo.Migrations.CreateNotes do
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
      add :note_id, references(:notes, on_delete: :delete_all)

      timestamps()
    end

    create table("card_logs") do
      add :card_id, references(:cards, on_delete: :delete_all)

      timestamps()
    end
  end
end
