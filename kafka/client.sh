#!/usr/bin/env bash

kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ECF_Events --from-beginning