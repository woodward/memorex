# Anki Algorithm for Review Cards

From [Anki Algorithm Explained in 5 minutes!](https://www.youtube.com/watch?v=newlu_xQazU&t=289s)

Default starting ease: 250%
Default interval modifier: 100%
Default hard interval: 120%
Default easy bonus: 130%

Press <again>:  Go through lapse steps, then new interval becomes % of old interval AND subtract 20% from ease

Press <hard>:   new_interval = current_interval * 1.2 (default hard interval) * 1 (default interval modifier) 
AND subtract 15% from ease

Press <good>:   new_interval = current_interval * 2.5 (ease%) * 1 (default interval modifier) 
AND keep ease unchanged

Press <easy>:   new_interval = current_interval * 2.5 (ease%) * 1 (default interval modifier) * 1.3 (default easy bonus) 
AND add 15% to ease


Anki algorithm only applies to graduated (review) cards, not cards in the learning phase


The Anki scheduler is in `anki/pylib/anki/scheduler/v2.py`