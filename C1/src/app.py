from gettext import find
from json import loads
from IPython import embed


def pkt_parser(pkt, path):
    if path == "":
        return pkt["_source"]["layers"]
    out = pkt["_source"]["layers"]
    for el in path.split("/"):
        out = out[el]
    return out


def find_key(pkt, path):
    try:
        pkt_parser(pkt, path)
        return True
    except KeyError:
        return False


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
    print("found {} [404] response packets".format(len(res)))

    reqs = []
    for r in res:
        token = pkt_parser(r, "coap/coap.token")
        for pkt in cap:
            if (
                "coap" in pkt_parser(pkt, "frame/frame.protocols")
                and pkt_parser(pkt, "coap/coap.token") == token
                and pkt_parser(pkt, "coap/coap.code") == "1"
            ):
                if find_key(pkt, "coap/opt.observe"):
                    if pkt_parser(pkt, "coap/opt.observe") == "0":
                        reqs.append(pkt)
                else:
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
        if find_key(pkt, "mqtt/mqtt.topic") and find_key(pkt, "mqtt/mqtt.passwd"):
            if (
                "factory/department" in pkt_parser(pkt, "mqtt/mqtt.topic")
                and pkt_parser(pkt, "mqtt/mqtt.passwd") == "admin"
            ):
                res.append(pkt)
    print("found {} matching packets".format(len(res)))


def q5v2(cap):
    src = []
    res = []

    for pkt in cap:
        if find_key(pkt, "mqtt/mqtt.passwd"):
            if pkt_parser(pkt, "mqtt/mqtt.passwd") == "admin":
                src.append(
                    [pkt_parser(pkt, "ip/ip.src"), pkt_parser(pkt, "tcp/tcp.srcport")]
                )

    for pkt in cap:
        for s in src:
            if find_key(pkt, "mqtt/mqtt.topic") and find_key(
                pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype"
            ):
                if (
                    "factory/department" in pkt_parser(pkt, "mqtt/mqtt.topic")
                    and pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype") == "3"
                    and pkt_parser(pkt, "ip/ip.src") in s[0]
                    and pkt_parser(pkt, "tcp/tcp.srcport") in s[1]
                ):
                    if (
                        pkt_parser(pkt, "ip/ip.src") in s[0]
                        and pkt_parser(pkt, "tcp/tcp.srcport") in s[1]
                    ):
                        res.append(pkt)

    print("found {} matching packets".format(len(res)))


# How many publishes with QoS 2
# don’t receive the PUBREL?
def q7(cap):
    res = []
    for pkt in cap:
        if find_key(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.qos") and find_key(
            pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype"
        ):
            if (
                pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.qos") == "2"
                and pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype") == "3"
            ):
                res.append(pkt)
    print("found {} packets with QoS=2, ".format(len(res)), end="")

    for pkt in res:
        msgid = pkt_parser(pkt, "mqtt/mqtt.msgid")
        for pkt in cap:
            if find_key(pkt, "mqtt/mqtt.msgid") and find_key(pkt, "mqtt/mqtt.mgstype"):
                if (
                    pkt_parser(pkt, "mqtt/mqtt.msgid") == msgid
                    and pkt_parser(pkt, "mqtt/mqtt.mgstype") == "6"
                ):
                    res.remove(pkt)
    print("of which {} have no PUBREL response".format(len(res)))


# What is the average Will Topic Length specified by
# clients with empty Client ID?
def q8(cap):
    sum = 0
    count = 0
    for pkt in cap:
        if not find_key(pkt, "_ws.malformed") and find_key(pkt, "mqtt/mqtt.clientid"):
            if pkt_parser(pkt, "mqtt/mqtt.clientid") == "":
                if find_key(pkt, "mqtt/mqtt.willtopic_len"):
                    sum += int(pkt_parser(pkt, "mqtt/mqtt.willtopic_len"))
                    count += 1
    print(
        "found {} packets. average will topic length: {}".format(count, (sum / count))
    )


# What is the average MQTT message length of the CONNECT
# messages using MQTT v3.1 protocol? Why  messages have different size?
def q10(cap):
    sum = 0
    count = 0
    for pkt in cap:
        if (
            find_key(pkt, "mqtt/mqtt.ver")
            and find_key(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype")
            and find_key(pkt, "mqtt/mqtt.len")
        ):
            if (
                pkt_parser(pkt, "mqtt/mqtt.ver") == "3"
                and pkt_parser(pkt, "mqtt/mqtt.hdrflags_tree/mqtt.msgtype") == "1"
            ):
                sum += int(pkt_parser(pkt, "mqtt/mqtt.len"))
                count += 1
    print("average message length: {}".format(sum / count))


def main():
    cap = loads(open("cap.json").read())
    q4(cap)


if __name__ == "__main__":
    main()
