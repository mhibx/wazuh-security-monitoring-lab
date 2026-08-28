# Architecture Overview

The Wazuh lab follows a simple endpoint-to-SIEM architecture.

```text
Windows Endpoint
        │
        ▼
Wazuh Agent
        │
        ▼
Wazuh Manager
        │
        ▼
Indexer
        │
        ▼
Dashboard
```

## Components

### Windows Endpoint

The Windows endpoint generates security telemetry such as Windows Event Logs and Sysmon events.

### Wazuh Agent

The Wazuh Agent is installed on the Windows endpoint and collects relevant security events before forwarding them to the Wazuh Manager.

### Wazuh Manager

The Wazuh Manager receives and analyzes events from the endpoint.

It applies Wazuh detection rules and generates security alerts when the collected telemetry matches defined detection logic.

### Indexer

The Indexer stores processed security events and alerts so they can be searched and analyzed.

### Dashboard

The Wazuh Dashboard provides the interface used to search events, review alerts, and investigate security activity.

## Detection Flow

The overall monitoring workflow is:

```text
Windows Activity
        │
        ▼
Windows Event Logs / Sysmon
        │
        ▼
Wazuh Agent
        │
        ▼
Wazuh Manager
        │
        ├── Detection Rules
        │
        ▼
Security Alerts
        │
        ▼
Indexer
        │
        ▼
Wazuh Dashboard
        │
        ▼
SOC Investigation
```

## Repository Structure

The repository is organized around the main components of the lab:

```text
architecture/
└── index.md

configs/
└── sysmonconfig.xml

deployment/
├── agent-deployment.md
├── environment.md
└── wazuh-installation.md

detection/
├── custom-rules.md
└── sysmon-configuration.md

investigations/
├── incident-01-smb-authentication-failure.md
├── incident-02-smb-brute-force-detection.md
├── incident-03a-powershell-execution-benign.md
├── incident-03b-powershell-encoded-command.md
└── incident-04-temporary-directory-executable.md

rules/
├── 100100-brute-force.xml
└── local_rules.xml

screenshots/

scripts/
├── script.md
└── smb_failed_login.sh
```

This structure separates deployment documentation, detection engineering, investigation write-ups, configuration files, and supporting evidence.

## Lab Purpose

The architecture is designed to support hands-on SOC practice, from endpoint telemetry collection through detection and investigation.

The lab is also used to validate custom Wazuh rules, analyze Windows and Sysmon events, and document investigation workflows.
