---
title: Home Challenge \#4
author: Francesco Pallotta
---

## Overview of the simulation log

Since my codice persona is 10783751, $X$ and $Y$ are respectively 2 and 83, meaning that mote #2 has to boot after 83 seconds, and that mote #1 has to stop the timer after receiving 2 `REQ-ACK`s. The file called `thistory.log` contains the execution log of the two motes. The first entries are just recording of mote #1 sending `REQ` packets without receiving `ACK`, since mote #2 is turned off:

```js
DEBUG (1): CH4App: [Mote 1] REQ sent
ERROR (1): CH4App: ACK not received. Waiting for next timer call...
DEBUG (1): timer: [84000] timer fired, counter now is 83.
```

Then, when mote #2 boots we have the exchange of messages:

```sequence
Mote 1->Mote 2:REQ
Mote 2->Mote 1:REQ-ACK
Mote 1->Mote 2:RESP
Mote 2->Mote 1:RESP-ACK
```

A single interaction of this kind looks like the following in the `.log` file:

```js
DEBUG (1): CH4App: [Mote 1] REQ sent
DEBUG (2): CH4App [Mote 2]: REQ received
DEBUG (1): CH4App: [Mote 1] REQ-ACK received, X is now 1
DEBUG (2): CH4App: [Mote 2] Read done.
DEBUG (2): CH4App: [Mote 2] packet content:
	type: 2
	counter: 85
	data: 245
DEBUG (2): CH4App [Mote 2]: RESP sent
DEBUG (1): CH4App [Mote 1]: RESP received
```