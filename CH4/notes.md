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
2. Upon receipt of the Xth REQ-ACK message:
   1. Mote #1 stops to send requests
   2. The exercise is done
3. Use the  module `PacketAcknowledgements` to  send the  ACKs.

X = [last digit of person code] + 1

Y = person code without last three digits and first three digits.

![](assets/flow.png)

## Notes

* There's a draft on the VM and also on Webeep which we can use to write the code for the challenge: `SendACK_template/sendAckC.nc`.

* TOSSIM and Node-Red cannot interact right now, so we'll not use Node-Red for this challenge.

* The simulation with TOSSIM:

  * Mote #1 at time 0
  * Mote #2 after Y seconds

* Only one message type containing:

  * `msg_type`: REQ/RESP
  * `msg_counter`: incremental integer
  * `value`: value from the fake sensor

* Compile the mote’s code:

  ```shell
  $ make micaz sim
  ```

* Run the simulation

  ```shell
  $ python RunSimulationScript.py
  ```

  