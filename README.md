# Wazuh Security Monitoring Lab

A hands-on Security Information and Event Management (SIEM) lab built with Wazuh to simulate Windows security monitoring, log analysis, and threat detection in a home lab environment.


## Overview

This project demonstrates the deployment and configuration of a Wazuh SIEM environment for monitoring Windows endpoints.

The lab focuses on collecting Windows Event Logs, detecting suspicious activities, and analyzing security events using custom detection rules.

The objective is to strengthen practical SOC Analyst skills through hands-on experience with enterprise security monitoring.

Ubuntu 24.04
│
├── Wazuh Manager
├── Wazuh Dashboard
└── Filebeat

↓

Windows 11 Endpoint

↓

Windows Event Logs

↓

Wazuh Rules

↓

Security Alerts


## Technologies

- Ubuntu Server
- Wazuh
- Windows 11
- Sysmon (planned)
- PowerShell
- Docker


## Use Case

| Use Case                    | Status |
| --------------------------- | ------ |
| Failed Login Detection      | ✅     |
| Brute Force Detection       | ✅     |
| PowerShell Monitoring       | ✅     |
| Sysmon Monitoring           | 🔜     |
| Active Directory Monitoring | 🔜     |


## Structure

docs/
rules/
screenshots/
architecture/

## Skills Demonstrated

- SIEM Deployment
- Windows Event Analysis
- Threat Detection
- Log Investigation
- Detection Rule Configuration
- Security Monitoring

## Future Improvement

- Active Directory integration
- Sysmon monitoring
- MITRE ATT&CK mapping
- Custom Wazuh decoders
- Email alerting
