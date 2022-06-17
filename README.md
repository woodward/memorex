#  Memorex

Memorex is a [space repetition system](https://en.wikipedia.org/wiki/Spaced_repetition) written in Elixir that is a [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) application.  Memorex utilizes [Anki's](https://apps.ankiweb.net/) spaced repetition algorithm, which is itself based on the [SuperMemo SM-2 algorithm](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html).  Unlike Anki, Memorex stores the flashcard content (i.e., notes) in Markdown files on your local filesystem.  The database is used only to store information related to drilling/drilling the flashcards, such as the due date for a card, its time interval, the number of repetitions, etc.

To use Memorex, first get it running on your local system.  First, you'll need to set an environment variable `MEMOREX_NOTE_DIRS` which points to one or more directories on your filesystem which contain Markdown files and/or directories with your flashcard content.  If you're using `direnv`, then see [.envrc.sample](https://github.com/woodward/memorex/blob/main/.envrc.sample) for an example `.envrc` file (note that only `MEMOREX_NOTE_DIRS` is required).

```
  mix deps.get
  mix deps.compile
  mix ecto.setup
```

## Decks

A deck consists either of a Markdown file (in which case the deck name is the name of the markdown file [minus the `.md` extension]), or a directory which contains multiple markdown files (in which case the deck name is the name of the directory).  A note consists of a line of text which contains either the unidirectional or bidirectional note delimitter. For example, for the `vim` deck with a bidirectional delimitter "⮂":

```
  How do you go to the end of a file?   ⮂  G
```

or for a unidirectional delimitter "→" in a deck `country-capitals.md`:

```
  What is the capital of France?  →  Paris
```

You can specify both the bidirectional and unidirectional delimitters in environment variables if you wish to override Memorex's default values.  The key idea is to have them be characters (or sequences of characters) which are relatively unique and would not otherwise show up in your note content.  You can intermix unidirectional and bidirectional delimitters within a single deck.

You can also put non-flashcard content in your deck Markdown files which will not be converted into flashcards; if a line doesn't have one of the delimitters, then it will simply be skipped over by the Memorex parser.  This way you can take notes, and create flashcards only for certain pieces of content within that note file.

## Notes and Cards

A note is a line from one of your decks which has either the unidirectional or bidirectional character in it.  Cards are what are actually drilled; forward and reverse cards are created if the bidirectional delimitter is present, and a single forward card is created if the unidirectional delimitter is present (i.e., a note has one or two associated cards).  That is, a deck contains many notes, and each note has one or two cards.

If you update the content of the Markdown files which comprise your decks, the notes & cards will be updated the next time you start Memorex.  Any existing card whose parent note has been edited will be reset to start out as a `:new` card again (i.e., the drilling information associated with the card will be lost), although the note content will be updated within Memorex.  This is because Memorex creates a linkage from the note in the Markdown file to the note in its database via a UUID based on a hash of the note content (along with the filename if the Markdown file is within a directory).

## Configuration

Memorex's settings mimic closely the settings from Anki; see a detailed list of the Anki settings in this [Anki forum](https://forums.ankiweb.net/t/deck-options-explained/213), and the [Anki manual](https://docs.ankiweb.net/deck-options.html) also contains a lot of information. You can override settings for all decks via environment variables; look in [this file](https://github.com/woodward/memorex/blob/main/.envrc.sample) or [in this file](https://github.com/woodward/memorex/blob/main/config/runtime.exs) to see a list of available environment variables. 

You can also override settings on a per-deck basis.  If your deck is a single markdown file (e.g., `my-deck.md`) then you can override settings for this deck by placing a config file named `my-deck.deck_config.toml` adjacent to the deck file in your directory structure.  If the deck is a directory, then just place a file named `deck_config.toml` within the directory.  See this [example deck settings file](https://github.com/woodward/memorex/blob/main/deck_config.example.toml) to see the format of the settings and what is available.  Note that if a value isn't specified, then the setting will default to either the environment variable's value (if one has been specified for this setting) or to Memorex's default value (so you only need to specify deck settings in the toml files for values that you wish to override).

## Drilling/Reviewing Cards

Similar to Anki, there are four answers for a flashcard: `again` (which means you failed to answer the card), `hard`, `good`, and `easy`.  When you start to drill for the day, you'll need to convert a batch of `:new` cards to `:learn` cards on the deck listing page.

## Development Process

Memorex's domain code (e.g., in [`lib/memorex`](https://github.com/woodward/memorex/tree/main/lib/memorex) ) was created using test-driven development (TDD), and as such has an extremely high level of test coverage (close to 100%, in fact). The Anki algorithm was painstakingly researched and unwound, and test cases were created for every scenario.  The code was also written with testability in mind; for example, `Timex.now()` is passed into most functions (rather than being called from within functions), and the actual Anki logic is performed in [CardStateMachine](https://github.com/woodward/memorex/blob/main/lib/memorex/scheduler/card_state_machine.ex) which consists of pure functions and does not interact with the database.  By contrast, the [LiveView code](https://github.com/woodward/memorex/tree/main/lib/memorex_web) was only lightly tested, though.

## Future Features

Support for mathematical formulas is on the roadmap (via [KaTeX](https://katex.org/)).  [Livebook](https://github.com/livebook-dev/livebook) integration is also a possibility (if I can figure out what that looks like!)
