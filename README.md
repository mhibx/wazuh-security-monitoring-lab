# Wazuh Security Monitoring Lab

A hands-on security monitoring lab built from the ground up to practice SIEM deployment, Windows endpoint monitoring, network intrusion detection, log analysis, threat detection, and security investigation in a self-hosted environment.

## Overview

This project started as a Wazuh-based SIEM lab for monitoring a Windows 11 endpoint and investigating security events.

As the lab evolved, I expanded it with Sysmon for additional Windows telemetry and Suricata as a network intrusion detection system (IDS). This allows the lab to cover both endpoint and network-based security monitoring.

The main focus is understanding the complete detection workflow rather than simply deploying security tools:

**Generate activity → collect telemetry → detect an event → investigate the alert → document the findings**

## Lab Architecture

~~~text
                         ┌──────────────────────┐
                         │      Ubuntu 24.04     │
                         │                      │
                         │  Wazuh Manager       │
                         │  Wazuh Dashboard     │
                         │  Filebeat             │
                         │  Suricata             │
                         └──────────┬───────────┘
                                    │
                 ┌──────────────────┴──────────────────┐
                 │                                     │
                 ▼                                     ▼
        ┌─────────────────┐                  ┌─────────────────┐
        │  Windows 11     │                  │   Kali Linux    │
        │                 │                  │                 │
        │ Wazuh Agent     │                  │ Nmap            │
        │ Sysmon          │                  │ Attack Testing  │
        └────────┬────────┘                  └────────┬────────┘
                 │                                    │
                 ▼                                    ▼
        Windows Event Logs                    Network Traffic
                 │                                    │
                 ▼                                    ▼
        Wazuh Detection Rules                     Suricata
                 │                                    │
                 └────────────────┬───────────────────┘
                                  ▼
                           Security Alerts
                                  │
                                  ▼
                         Investigation & Tuning
~~~

## Technologies

- Ubuntu 24.04
- Wazuh
- Wazuh Agent
- Wazuh Dashboard
- Filebeat
- Windows 11
- Sysmon
- Suricata
- Kali Linux
- Nmap
- PowerShell
- Docker

## Detection & Monitoring Use Cases

| Use Case | Status |
|----------|:------:|
| Failed Login Detection | Completed |
| Brute Force Detection | Completed |
| PowerShell Monitoring | Completed |
| Sysmon Monitoring | Completed |
| Network Traffic Monitoring with Suricata | Completed |
| Suricata Alert Ingestion into Wazuh | Completed |
| Wazuh Alert Correlation & Tuning | In Progress |
| Active Directory Monitoring | Planned |

## Project Structure

~~~text
docs/
rules/
screenshots/
architecture/
~~~

The repository contains supporting documentation, custom detection rules, screenshots, and architecture references from the lab.

## Skills Practiced

- SIEM Deployment
- Windows Event Analysis
- Network Traffic Analysis
- Log Analysis
- Threat Detection
- Security Monitoring
- Detection Rule Configuration
- IDS Integration
- Alert Correlation
- Incident Investigation

## What I Learned

Building the environment from scratch helped me understand how different security monitoring components work together.

On the endpoint side, I practiced collecting and investigating Windows security telemetry through Wazuh and Sysmon.

On the network side, I used Suricata to inspect traffic and generate IDS alerts from simulated activity, including Nmap scans from a Kali Linux attacker machine.

The lab also helped me understand that generating an alert is only one part of detection engineering. The next step is determining which events are meaningful, reducing unnecessary alerts, and correlating related activity so that an analyst can investigate a security event more efficiently.

## Future Improvements

- Complete Wazuh correlation and alert tuning for Suricata events
- Active Directory integration
- MITRE ATT&CK mapping
- Custom Wazuh decoders
- Advanced Sysmon detection rules
- Email alerting
- Additional network-based detection use cases
