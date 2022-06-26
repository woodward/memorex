# ![Memorex](https://github.com/woodward/memorex/blob/main/priv/static/images/memorex-logo.svg?raw=true)

Memorex is a [space repetition system](https://en.wikipedia.org/wiki/Spaced_repetition) written in Elixir and implemented as a [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) application.  You can read its [documentation here](https://hexdocs.pm/memorex/). Memorex utilizes [Anki's](https://apps.ankiweb.net/) spaced repetition algorithm, which is itself based on the [SuperMemo SM-2 algorithm](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html).  Unlike Anki, Memorex stores the flashcard content (i.e., notes) in Markdown files on your local filesystem (or as image files, each with an associated text file which contains the description of the image file).  The database is only used to store information related to drilling/reviewing the flashcards, such as the due date for a card, its time interval, the number of repetitions, etc.

To use Memorex, first get it running on your local system.  First, you'll need to set an environment variable `MEMOREX_NOTE_DIRS` which points to one or more directories on your filesystem which contain Markdown files and/or directories with your flashcard content.  If you're using `direnv`, then see [.envrc.sample](https://github.com/woodward/memorex/blob/main/.envrc.sample) for an example `.envrc` file (note that only `MEMOREX_NOTE_DIRS` is required).

```
  mix deps.get
  mix deps.compile
  mix ecto.setup
```

Then create one or more Markdown files with notes (or image files with similarly named text file which contains the "answer"); see [`test/fixtures/contains_multiple_decks`](https://github.com/woodward/memorex/tree/main/test/fixtures/contains_multiple_decks) for some examples (using test data), or [vim-flashcards](https://github.com/woodward/vim-flashcards) for a real-life deck example.  Then read in the notes and start up the Phoenix app via the following:

```
  mix memorex.read_notes
  iex -S mix phx.server
```

Navigate in your browser to `http://localhost:4000`.  All of the newly read notes start out as `:new` cards.  Convert a bunch of `:new` cards to `:learn` cards by hitting the button "Add New Learn Cards", and then review some cards by hitting the "Review/Drill" button!

## Decks, Notes, and Cards

A `Memorex.Domain.Deck` consists either of a Markdown file (in which case the deck name is the name of the markdown file [minus the `.md` extension]), or a directory which contains multiple markdown files and/or image & text files (in which case the deck name is the name of the directory).  There are two types of notes in `Memorex`; "text notes" and "image notes".  A text note consists of a line of text in a Markdown file which contains either the unidirectional or bidirectional note delimitter. For example, for the `vim` deck with a bidirectional delimitter "⮂", a note might consist of the following:

```
  How do you navigate to the end of a file?   ⮂  G
```

or for a unidirectional delimitter "→" in a deck `country-capitals.md`, a note may be:

```
  What is the capital of France?  →  Paris
```

You can specify both the bidirectional and unidirectional delimitters in environment variables if you wish to override Memorex's default values.  The key idea is to have them be characters (or sequences of characters) which are relatively unique and would not otherwise show up in your note content.  You can intermix unidirectional and bidirectional delimitters within a single deck.

You can also put non-flashcard content in your deck Markdown files which will not be converted into flashcards; if a line doesn't have one of the delimitters, then it will simply be skipped over by the `Memorex.Parser`.  This way you can take notes, and create flashcards only for certain pieces of content within that note file that you wish you drill on later.

Image notes consist of a image files placed within a deck directory; each image file has a text file adjacent to it which contains the "answer" to the image.  For example, if the image file is "sequoia.jpg" then the sibling text file "sequoia.txt" might contain "Sequoia Sempervirens - Coastal Redwood".  Image notes can have the extensions ".jpg", ".jpeg", ".png", ".webp", ".svg", or ".gif".

A `Memorex.Domain.Note` is a line from one of your decks which has either the unidirectional or bidirectional character in it (for text notes), OR an image file/text/file pair (for image notes).  `Memorex.Domain.Card`s are what are actually drilled; forward and reverse cards are created from a note if the bidirectional delimitter is present, and a single forward card is created from a note if the unidirectional delimitter is present (i.e., a note has one or two associated cards).  That is, a deck contains many notes, and each note has one (or two) cards.  When you answer a card, a `Memorex.Domain.CardLog` entry is created.

If you update the content of the Markdown files which comprise your decks, the notes & cards will be updated the next time you run the mix task `mix memorex.read_notes`.  Any existing card whose parent note has been edited will be reset to start out as a `:new` card again (i.e., the drilling information associated with that card will be lost), although the note content will be updated within Memorex.  This is because Memorex creates a linkage from the note in the Markdown (for text notes) file to the note in its database via a UUID based on a hash of the note content (together with the filename if the Markdown file is within a directory).  Similary for image notes, the notes & cards will be updated if either the image file content is changed, the content of its sibling text file is changed, or if the image & text file are moved to a different location (for example, moving the image file/text file pair to a different deck directory).

## Note Categories

Multiple Markdown files within a deck directory will result in the notes for that deck each having a "category" which is the name of the Markdown file.  If Markdown note files (or image files with their corresponding text files) are in subdirectories within a deck directory, then the notes will have categories which are the names of the subdirectories (plus the name of the Markdown file if these are text notes).  For example, for a deck directory named "Spanish Vocabulary", a Markdown file within that directory called `Spanish Vocabulary/Nouns/Household.md` which contains the note line `lavavajillas ⮂ dishwasher` will result in a bidirectional note which has the category `Nouns => Household`.  Similarly for image notes, if there is a image file/text file pair `coast-live-oak.jpg` and `coast-live-oak.txt` within a subdirectory inside of deck directory named `California Native Plants`, such as `California Native Plants/Trees/Coastal/coast-live-oak.jpg` and `California Native Plants/Trees/Coastal/coast-live-oak.txt`, then the resulting note will have the category `Trees => Coastal`.

## Configuration

Memorex's settings mimic closely the settings from Anki; see a detailed list of the Anki settings in this [Anki forum](https://forums.ankiweb.net/t/deck-options-explained/213).  The [Anki manual](https://docs.ankiweb.net/deck-options.html) also contains a lot of information. You can override settings for all decks via environment variables; look in [this file](https://github.com/woodward/memorex/blob/main/.envrc.sample) or [in this file](https://github.com/woodward/memorex/blob/main/config/runtime.exs) to see a list of available environment variables. 

You can also override settings on a per-deck basis.  If your deck is a single markdown file (e.g., `my-deck.md`) then you can override settings for this deck by placing a config file named `my-deck.deck_config.toml` adjacent to the deck file in your directory structure.  If the deck is a directory, then just place a file named `deck_config.toml` within the directory.  See this [example deck settings config file](https://github.com/woodward/memorex/blob/main/deck_config.example.toml) to see the format of the settings and what is available.  Note that if a value isn't specified, then the setting will default to either the environment variable's value (if one has been specified for this setting) or to Memorex's default value, so you only need to specify deck settings in the toml files for values that you wish to override.  The current Memorex defaults are all equal to the Anki defaults, and Anki recommends that you use the default values for a few weeks and become comfortable with them before changing/customizing them.

## Drilling/Reviewing Cards

Similar to Anki, there are four answers for a flashcard: `:again` (which means you failed to answer the card), `:hard`, `:good`, and `:easy`.  When you start to drill for the day, you'll need to convert a batch of `:new` cards to `:learn` cards on the deck listing page.  A `Memorex.Domain.Card` starts out as a `:new` card; it is converted to a `:learn` card (by hitting the button on the `MemorexWeb.DecksLive` page) so that it can be drilled/reviewed. After progressing through the learning steps, the card becomes a `:review` card.  If a `:review` card is failed (i.e., you answer it as `:again` then it is said to have lapsed, and becomes a `:relearn` card.  It then must progress through the `:relearn` steps in order to become a `:review` card again.  After `:leech_threshold` lapses in `Mememorex.Scheduler.Config` (by default, 8 lapses) then card switches from being `:active` to `:suspended`.  All of this mirrors the Anki algorithm.

## Differences with Anki

There is no notion of a "user" within Memorex nor shared decks; you share flashcard decks with other people by simply sharing the git repo which contains the flashcards.  

## Duration Fields

Duration fields (such as `max_review_interval`, `min_review_interval`, etc.) in `Memorex.Scheduler.Config` are specified using [ISO-8601 format](https://en.wikipedia.org/wiki/ISO_8601#Times) in environment variables and config files.  For example, "P1M10D" means "1 month, 10 days", and "P3DT4H30M" means "3 days, 4 hours, & 30 minutes".

## Development Process

Memorex's domain code (e.g., in [`lib/memorex`](https://github.com/woodward/memorex/tree/main/lib/memorex) ) was created using a strict test-driven development (TDD) approach, and as such has an extremely high level of test coverage (close to 100%, in fact). The Anki algorithm was painstakingly researched and unwound, and test cases were created for every scenario (in fact, in the process of developing Memorex I found some existing documentation was incorrect by examining and running the tests in the Anki source code).  The code for Memorex was also written with testability in mind; for example, `Timex.now()` is passed into most functions (rather than being called from within functions) so that time is deterministic for testing purposes, and the actual Anki logic is performed in a single module, [CardStateMachine](https://github.com/woodward/memorex/blob/main/lib/memorex/scheduler/card_state_machine.ex), which consists of pure functions and does not interact with the database nor external time. Some functions in various modules are made public that would normally be private functions just so that they can be properly tested (for example, `Memorex.Parser` has only one externally used function `read_note_dirs/1`, but a lot of the other functions in there are public so they can be tested).  By contrast, the [LiveView code](https://github.com/woodward/memorex/tree/main/lib/memorex_web) was only lightly tested, though (as time permits, I would like to backfill LiveView tests for these LiveViews, though!)

## Future Features

Support for mathematical formulas is on the roadmap (via [KaTeX](https://katex.org/)).  [Livebook](https://github.com/livebook-dev/livebook) integration is also a possibility (if I can figure out what that looks like!)
