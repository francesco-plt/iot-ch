# Challenge 4

Challenge structure:

* Develop TinyOS app
* Simulate it with TOSSIM

`.zip` content:

* TinyOS code
* Python code
* Topology
* Noise
* Execution logs from terminal
* Short report
* Repository link

## What do we do?

We'll have two motes, the first one sends requests while the second one sends responses. The first asks for a value and the second one answers with that value, which is a random number generated with a random library.

## Message format

Mote 1:

1. Message type (REQ)
2. Counter

The request has periodicity 1000ms.

Mote 2:

* Message type (RESP)
* Counter sent by mote #1
* Value read from fake sensor

## Rules

1. Each message (REQ/RESP) must be acknowledged using the built-in ACK module
2. 

![](assets/flow.png)

## Notes

* There's a draft on the VM and also on Webeep which we can use to write the code for the challenge: `sendAckC.nc`.
* TOSSIM and Node-Red cannot interact right now, so we'll not use Node-Red for this challenge.