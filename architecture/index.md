# Security Monitoring Architecture

This document describes the architecture of the security monitoring lab, including endpoint telemetry, network monitoring, log collection, and SIEM analysis.

## Architecture Overview

```text
                              ┌──────────────────────┐
                              │     Kali Linux       │
                              │   Attack Simulation  │
                              └──────────┬───────────┘
                                         │
                              Network Traffic / Attacks
                                         │
                                         ▼
                              ┌──────────────────────┐
                              │      Suricata        │
                              │ Network Monitoring   │
                              └──────────┬───────────┘
                                         │
                                   EVE JSON Logs
                                         │
                                         │
┌──────────────────────┐                 │
│   Windows Endpoint   │                 │
│      Windows 11      │                 │
└──────────┬───────────┘                 │
           │                             │
           ├── Windows Event Logs        │
           │                             │
           └── Sysmon Telemetry          │
                  │                      │
                  ▼                      │
          ┌──────────────────┐           │
          │   Wazuh Agent    │           │
          └────────┬─────────┘           │
                   │                     │
                   └──────────┬──────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │    Wazuh Manager     │
                   │  Log Analysis &      │
                   │  Detection Engine    │
                   └──────────┬───────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │       Indexer        │
                   │   Security Events    │
                   └──────────┬───────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │      Wazuh Dashboard │
                   │ Monitoring &         │
                   │ Investigation        │
                   └──────────────────────┘
