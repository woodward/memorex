defmodule Memorex.Repo.Migrations.CreateNotes do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table("notes") do
      add :contents, {:array, :binary}

      timestamps()
    end
  end
end
