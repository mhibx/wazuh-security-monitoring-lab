# Wazuh Security Monitoring Lab

A hands-on security monitoring lab built with Wazuh to practice Windows endpoint monitoring, log analysis, threat detection, and security investigation in a self-hosted environment.

## Overview

This project focuses on building a small security monitoring environment from the ground up and using it to investigate Windows security events.

The lab currently uses Ubuntu as the Wazuh server and Windows 11 as the monitored endpoint. Windows Event Logs are collected by the Wazuh agent and analyzed using Wazuh's built-in and custom detection rules.

The main goal of the project is to understand the process behind security monitoring rather than simply deploying a SIEM:

**Generate activity → collect telemetry → detect an event → investigate the alert → document the findings**

## Lab Architecture

~~~text
Ubuntu 24.04
│
├── Wazuh Manager
├── Wazuh Dashboard
└── Filebeat
        │
        ▼
Windows 11 Endpoint
        │
        ▼
Windows Event Logs
        │
        ▼
Wazuh Rules
        │
        ▼
Security Alerts
~~~

## Technologies

- Ubuntu 24.04
- Wazuh
- Windows 11
- Sysmon
- PowerShell
- Docker

## Use Cases

| Use Case | Status |
|----------|:------:|
| Failed Login Detection | Completed |
| Brute Force Detection | Completed |
| PowerShell Monitoring | Completed |
| Sysmon Monitoring | Completed |
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
- Log Analysis
- Threat Detection
- Security Monitoring
- Detection Rule Configuration
- Incident Investigation

## What I Learned

Building the lab from scratch helped me understand how security monitoring works across the different stages of the detection process.

Instead of treating alerts as isolated events, I practiced tracing them back to the underlying Windows activity and examining the available telemetry to understand what happened.

This also gave me a practical foundation for developing custom detection rules and documenting security investigations.

## Future Improvements

- Active Directory integration
- MITRE ATT&CK mapping
- Custom Wazuh decoders
- Advanced Sysmon detection rules
- Email alerting
- Network IDS integration
