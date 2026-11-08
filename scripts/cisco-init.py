#!/usr/bin/env python3

import argparse
import logging
import os
import re
import sys
import time

from netmiko import ConnectHandler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

COMMANDS = [
    "lldp run",
    "cdp run",
    "interface Ethernet0/1",
    "description TO-LINUX-R3",
    "no shutdown",
    "lldp transmit",
    "lldp receive",
    "interface Ethernet0/2",
    "description TO-LINUX-R1",
    "no shutdown",
    "lldp transmit",
    "lldp receive",
]

EXPECTED_INTERFACES = ("Ethernet0/1", "Ethernet0/2")


def connect(host, username, password, timeout):
    deadline = time.monotonic() + timeout

    while time.monotonic() < deadline:
        try:
            connection = ConnectHandler(
                device_type="cisco_ios",
                host=host,
                username=username,
                password=password,
                conn_timeout=10,
                auth_timeout=10,
                banner_timeout=10,
            )
            logging.info("CISCO_SSH_READY host=%s", host)
            return connection
        except Exception as exc:
            logging.warning("CISCO_SSH_WAIT error=%s", exc)
            time.sleep(5)

    raise TimeoutError("Cisco SSH did not become available")


def check_interfaces(connection):
    output = connection.send_command("show ip interface brief")
    logging.info("CISCO_INTERFACE_STATUS\n%s", output)

    for interface in EXPECTED_INTERFACES:
        pattern = (
            rf"^{re.escape(interface)}\s+\S+\s+\S+\s+\S+\s+"
            rf"up\s+up\s*$"
        )
        if not re.search(pattern, output, re.MULTILINE):
            raise RuntimeError(f"{interface} is not up/up")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="172.30.211.243")
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()

    username = os.getenv("CISCO_USERNAME", "admin")
    password = os.getenv("CISCO_PASSWORD")

    if not password:
        raise RuntimeError("CISCO_PASSWORD environment variable is required")

    connection = connect(args.host, username, password, args.timeout)

    try:
        logging.info("CISCO_CONFIG_START host=%s", args.host)
        output = connection.send_config_set(COMMANDS)
        logging.info("CISCO_CONFIG_OUTPUT\n%s", output)

        time.sleep(5)
        check_interfaces(connection)

        connection.save_config()
        logging.info("CISCO_CONFIG_SUCCESS host=%s", args.host)
    finally:
        connection.disconnect()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        logging.exception("CISCO_CONFIG_FAILED")
        sys.exit(1)
