defmodule Memorex.Repo.Migrations.CreateNotes do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table("notes") do
      add :content, {:array, :binary}
      add :in_latest_parse?, :boolean, default: false, null: false

      timestamps()
    end
  end
end
