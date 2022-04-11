from json import loads
from difflib import Differ
from IPython import embed


def pkt_parser(pkt, rel_path):
    out = pkt["_source"]["layers"]
    for el in rel_path.split("/"):
        out = out[el]
    return out


# How many GET requests, excluding OBSERVE
# requests, have been directed to non existing
# resources?
def q4(cap):
    res = []
    for pkt in cap:
        if (
            "coap" in pkt_parser(pkt, "frame/frame.protocols")
            and pkt_parser(pkt, "coap/coap.code") == "132"
        ):
            res.append(pkt)
    print("found {} 404 response packets".format(len(res)))

    reqs = []
    for r in res:
        token = pkt_parser(r, "coap/coap.token")
        for pkt in cap:
            if (
                "coap" in pkt_parser(pkt, "frame/frame.protocols")
                and pkt_parser(pkt, "coap/coap.token") == token
                and pkt_parser(pkt, "coap/coap.code") == "1"
            ):
                try:
                    if pkt_parser(pkt, "coap/opt.observe") == "0":
                        reqs.append(pkt)
                except KeyError as e:
                    reqs.append(pkt)
    print("found {} matching responses".format(len(reqs)))


# How many messages containing the topic
# “factory/department*/+” are published by a client with
# user password: “admin”?
# Where * replaces only the dep. number [0-9], e.g.
# factory/department1/+, factory/department2/+ and so on.
def q5(cap):
    res = []
    for pkt in cap:
        try:
            if (
                "factory/department" in pkt_parser(pkt, "mqtt/mqtt.topic")
                and pkt_parser(pkt, "mqtt/mqtt.passwd") == "admin"
            ):
                res.append(pkt)
        except KeyError as e:
            pass
    print("found {} matching packets".format(len(res)))


# How many clients connected to the public broker
# "mosquitto" have specified a will message?
def q6(cap):
    res = []
    for pkt in cap:
        try:
            if (
                "mosquitto" in pkt_parser(pkt, "dns/Queries/dns.qry.name")
                and pkt_parser(pkt, "mqtt/mqtt.willmsg") != ""
            ):
                res.append(pkt)
        except KeyError as e:
            pass
    print("found {} matching packets".format(len(res)))


# How many publishes with QoS 2 don’t receive the
# PUBREL?
def q7(cap):
    res = []
    pubs = []
    for pkt in cap:
        try:
            if pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.qos") == "2":
                pubs.append(pkt)
        except KeyError:
            pass
    print("found {} packets with QoS=2".format(len(pubs)))

    for p in pubs:
        msgid = pkt_parser(p, "mqtt/mqtt.msgid")
        for pkt in cap:
            try:
                if (
                    pkt_parser(pkt, "mqtt/mqtt.msgid") == msgid
                    and pkt_parser(pkt, "mqtt/mqtt.mgstype") == "6"
                ):
                    res.append(pkt)
            except KeyError:
                pass
    print("found {} matching packets".format(len(res)))


# What is the average Will Topic Length specified by
# clients with empty Client ID?
def q8(cap):
    sum = 0
    count = 0
    for pkt in cap:
        try:
            if pkt_parser(pkt, "mqtt/mqtt.clientid") == "":
                try:
                    sum += int(pkt_parser(pkt, "mqtt/mqtt.willtopic_len"))
                    count += 1
                except KeyError:
                    pass
        except KeyError:
            pass
    print("average will topic length: {}".format(sum / count))


# How many ACKs received the client with ID 6M5H8y3HJD5h4EEscWknTD? What type(s) is(are) it(them)?
def q9(cap):
    for pkt in cap:
        try:
            if pkt_parser(pkt, "mqtt/mqtt.clientid") == "6M5H8y3HJD5h4EEscWknTD":
                print(pkt_parser(pkt, "mqtt/mqtt.mgstype"))
        except KeyError:
            pass


# What is the average MQTT message length of the CONNECT
# messages using MQTT v3.1 protocol? Why  messages have different size?
def q10(cap):
    sum = 0
    count = 0
    for pkt in cap:
        try:
            if (
                pkt_parser(pkt, "mqtt/mqtt.ver") == "3"
                and pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype") == "1"
            ):
                sum += int(pkt_parser(pkt, "mqtt/mqtt.len"))
                count += 1
        except KeyError:
            pass
    print("average message length: {}".format(sum / count))


def main():
    cap = loads(open("cap.json").read())
    q10(cap)


if __name__ == "__main__":
    main()
