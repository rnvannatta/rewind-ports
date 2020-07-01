# rewind-ports
Rewindable Input Ports for Chicken Scheme

In Scheme, when Input Ports are read from, the characters are consumed and the state of the port is permanently advanced to the next character in the queue. This works fine for minimal input parsers consisting of a single large state machine, but is insufficent for more advanced or more maintainable use-cases. In the event of a failure, the state can not be unwound and restored to before the failure, leaving the only option to either ensure that any IO logic cannot fail (e.g. simply reading it to a buffer), or having to completely restart (i.e. closing and opening the file again).

One solution to this, which Guile Scheme uses, is to have an `(unget)` procedure which pushes a character onto the front of the port. While this works, it ends up being clumsy and inefficient. This library instead provides functionality similar to `ftell()` and `fseek()` where the current IO cursor can be saved off, and then restored later. This is achieved by maintaining an internal stream of characters, where cursors are references to elements in the stream. If no cursors are saved, that section of the stream is dangling and garbage collected. In practice, this was a massive improvement in performance for parsing, as my regex engine didn't have to save off the array of characters, and then iterate over them, `(unget)`ing each character in the event of a failure. So the amount of garbage generated was halved as was the work done to save the characters. It also reduced the number of variables needing to be maintained and passed around.

Usage:

```
(define rewindable-input (port->rewind-port (open-input-string "one two")))
(read rewindable-input) ; returns one
(define saved-cursor (save-rewind-port rewindable-input))
(read rewindable-input) ; returns two
(rewind-port-seek! rewindable-input saved-cursor) ; restores port cursor to the space after one
(read rewindable-input) ; returns two
```
