https://forums.ankiweb.net/t/deck-options-in-a-mental-map/15757

https://aws1.discourse-cdn.com/standard11/uploads/anki2/original/2X/8/852e362b5c6f1208feec3ac01047d6deab5e4a43.jpeg

May 27, 2022


NOTE:  the picture is WRONG for ansering :hard for review cards - you DO NOT multiply by the ease!!!

---------------------------------
It is also wrong for answering :good 
The picture:
interval = interval * card.ease_factor * config.interval_multiplier

From the Anki code:
interval = (interval + (time.now - card.due)/2) * card.ease_factor * config.interval_multiplier

---------------------------------

It is also wrong for answering :easy 
The picture:
interval = interval * card.ease_factor * config.interval_multiplier * config.easy_multiplier

From the Anki code:
interval = (interval + (time.now - card.due)) * card.ease_factor * config.interval_multiplier * config.easy_multiplier

---------------------------------

This is explained here:
https://faqs.ankiweb.net/due-times-after-a-break.html
