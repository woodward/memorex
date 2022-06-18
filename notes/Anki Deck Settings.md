# Anki Deck Settings

These are the settings for a deck; get to these values by clicking on the gear icon to the right of a deck name, and select "Options".

These are the tooltip values that show up when you hover on the "i" icon next to the value's name.  They are copied/pasted from the file [deck-config.ftl](https://github.com/ankitects/anki/blob/main/ftl/core/deck-config.ftl)

This [manual page](https://docs.ankiweb.net/deck-options.html) also talks about the various deck settings.  This [Anki page](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html) is also useful.  Read [here about the Anki 2.1 scheduler](https://faqs.ankiweb.net/the-anki-2.1-scheduler.html), and [here about the 2021 scheduler](https://faqs.ankiweb.net/the-2021-scheduler.html).


## Daily Limits

**New cards per day [default: 20]** - The maximum number of new cards to introduce in a day, if new cards are available.  Because new material will increase your short-term review workload, this should typically be at least 10x smaller than your review limit.

**Maximum reviews per day [default: 200]** - The maximum number of review cards to show in a day, if cards are ready for review.


## New Cards

**Learning steps [default: 1m 10m]** - One or more delays, separated by spaces. The first delay will be used when you press the `Again` button on a new card, and is 1 minute by default. The `Good` button will advance to the next step, which is 10 minutes by default. Once all steps have been passed, the card will become a review card, and will appear on a different day. Delays are typically minutes (eg `1m`) or days (eg `2d`), but hours (eg `1h`) and seconds (eg `30s`) are also supported.

**Graduating interval [default: 1]** -  The number of days to wait before showing a card again, after the `Good` button is pressed on the final learning step.

**Easy interval [default: 4]** - The number of days to wait before showing a card again, after the `Easy` button is used to immediately remove a card from learning.

**Insertion order [default: `Sequential (oldest cards first)`]** - Controls the position (due #) new cards are assigned when you add new cards. Cards with a lower due number will be shown first when studying. Changing this option will automatically update the existing position of new cards. (other value is `Random`)


## Lapses

**Relearning steps [default: 10 m]** - Zero or more delays, separated by spaces. By default, pressing the `Again` button on a review card will show it again 10 minutes later. If no delays are provided, the card will have its interval changed, without entering relearning. Delays are typically minutes (eg `1m`) or days (eg `2d`), but hours (eg `1h`) and seconds (eg `30s`) are also supported.

**Minimum interval [default: 1]** - The minimum interval given to a review card after answering `Again`.

**Leech threshold [default: 8]** - The number of times `Again` needs to be pressed on a review card before it is marked asa leech. Leeches are cards that consume a lot of your time, and when a card is marked as a leech, it's a good idea to rewrite it, delete it, or think of a mnemonic to help you remember it.

**Leech action [default: `Suspend Card`]** -  `Tag Only`: Add a "leech" tag to the note, and display a pop-up. `Suspend Card`: In addition to tagging the note, hide the card until it is manually unsuspended.


## Timer
 
**Maximum answer seconds [default: 60]** - The maximum number of seconds to record for a single review. If an answer exceeds this time (because you stepped away from the screen for example), the time taken will be recorded as the limit you have set.

**Show answer timer [default: off]** - In the review screen, show a timer that counts the number of seconds you're taking to review each card.


## Burying

**Bury new siblings [default: off]** - Whether other cards of the same note (eg reverse cards, adjacent cloze deletions) will be delayed until the next day.

**Bury review siblings [default: off]** - Whether other cards of the same note (eg reverse cards, adjacent cloze deletions) will be delayed until the next day.


## Audio 

**Don't play audio automatically [default: off]** - (no tooltip given)

**Skip question when replaying answer [default: off]** - Whether the question audio should be included when the Replay action is used while looking at the answer side of a card.


## Advanced

**Maximum interval [default: 36500]** - The maximum number of days a review card will wait. When reviews have reached the limit, `Hard`, `Good` and `Easy` will all give the same delay. The shorter you set this, the greater your workload will be.

**Starting ease [default: 2.50]** - The ease multiplier new cards start with. By default, the `Good` button on a newly-learned card will delay the next review by 2.5x the previous delay.

**Easy bonus [default: 1.30]** - An extra multiplier that is applied to a review card's interval when you rate it `Easy`.

**Interval modifier [default: 1.00]** - This multiplier is applied to all reviews, and minor adjustments can be used to make Anki more conservative or aggressive in its scheduling. Please see the manual before changing this option.

**Hard interval [default: 1.20]** - The multiplier applied to a review interval when answering `Hard`.

**New interval [default: 0.00]** - The multiplier applied to a review interval when answering `Again`.










