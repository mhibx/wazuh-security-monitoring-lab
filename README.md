# Wazuh Security Monitoring Lab

A hands-on SOC monitoring and security investigation lab built from the ground up to practice SIEM deployment, Windows endpoint monitoring, network intrusion detection, alert triage, log analysis, threat detection, and incident investigation in a self-hosted environment.

The project focuses on understanding the analyst workflow behind a security alert — from telemetry collection and detection to investigation, MITRE ATT&CK mapping, findings, and recommended response.

---

## Overview

This project started as a Wazuh-based SIEM lab for monitoring a Windows 11 endpoint.

As the lab evolved, additional telemetry and detection capabilities were integrated:

- **Sysmon** for detailed Windows process and system telemetry
- **Suricata** for network intrusion detection
- **Kali Linux** for controlled attack simulation and network testing
- **Custom Wazuh rules** for detecting specific security behaviors

The lab is designed around a practical SOC workflow:

**Generate activity → Collect telemetry → Detect → Triage → Investigate → Map to MITRE ATT&CK → Document findings → Recommend response**

Rather than focusing only on whether an alert was generated, the project emphasizes understanding **why the alert fired, what evidence supports it, and how an analyst should respond.**

---

## Lab Architecture

The detailed architecture documentation is available in:

`docs/architecture/`

High-level architecture:

~~~text
                         ┌──────────────────────┐
                         │      Ubuntu 24.04     │
                         │                      │
                         │  Wazuh Manager       │
                         │  Wazuh Dashboard     │
                         │  Wazuh Indexer       │
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
        │ Wazuh Agent     │                  │ Attack Testing  │
        │ Sysmon          │                  │ Nmap            │
        └────────┬────────┘                  └────────┬────────┘
                 │                                    │
                 ▼                                    ▼
        Windows Event Logs                    Network Traffic
                 │                                    │
                 ▼                                    ▼
             Sysmon                              Suricata
                 │                                    │
                 └────────────────┬───────────────────┘
                                  ▼
                           Wazuh Detection
                                  │
                                  ▼
                             SOC Alert
                                  │
                                  ▼
                         Investigation & Triage
                                  │
                                  ▼
                      Findings / Recommendation
~~~

---

## Technologies

### SIEM & Security Monitoring

- Wazuh
- Wazuh Manager
- Wazuh Indexer
- Wazuh Dashboard
- Filebeat

### Endpoint Monitoring

- Windows 11
- Wazuh Agent
- Sysmon
- PowerShell
- Windows Event Logs

### Network Monitoring

- Suricata
- Nmap
- Kali Linux

### Environment & Tooling

- Ubuntu 24.04
- Docker
- Git / GitHub

---

## Detection & Investigation Use Cases

| ID | Use Case | MITRE ATT&CK | Status |
|----|----------|---------------|:------:|
| 01 | SMB Authentication Activity | — | Completed |
| 02 | SMB Brute Force Detection | — | Completed |
| 03a | Benign PowerShell Execution | T1059.001 | Completed |
| 03b | PowerShell Encoded Command | T1059.001 | Completed |
| 04 | Executable from Temporary Directory | T1204 / Execution Context | Completed |
| 05 | Account Discovery using `net user` via PowerShell | T1087.001, T1059.001 | Completed |

The investigations are documented in:

`investigations/`

Each investigation focuses on the available telemetry, detection logic, evidence, analyst reasoning, and recommended response.

---

## Investigation Workflow

The investigations in this lab follow a repeatable SOC analyst workflow:

### 1. Alert Identification

Determine what triggered the alert and identify the affected endpoint, event type, timestamp, and detection rule.

### 2. Initial Triage

Assess whether the activity appears suspicious, benign, or requires additional investigation.

### 3. Evidence Collection

Review relevant telemetry such as:

- Windows Event Logs
- Sysmon events
- Process creation data
- Command lines
- Parent-child process relationships
- User context
- Network activity
- Wazuh alerts

### 4. Investigation

Correlate available evidence to understand:

- What happened?
- Which process or user initiated the activity?
- What was the parent process?
- What command was executed?
- What system or account was affected?
- Is there evidence of malicious intent?

### 5. MITRE ATT&CK Mapping

Where applicable, observed behavior is mapped to relevant MITRE ATT&CK techniques.

### 6. Findings & Recommendation

The investigation concludes with an analyst assessment and recommended response or next investigative action.

---

## Detection Engineering

Custom Wazuh rules were created to detect specific behaviors observed during controlled testing.

Examples include:

- SMB authentication activity
- SMB brute-force behavior
- PowerShell execution
- Encoded PowerShell commands
- Executable activity from temporary directories
- Account discovery using `net user`

Detection rules are stored in:

`rules/`

Supporting configuration and validation documentation are available in:

`docs/`

---

## Suricata Integration

Suricata is integrated into the lab as a network intrusion detection system.

The integration allows network activity generated during controlled testing to be observed independently from endpoint telemetry.

Example activity includes:

- Nmap scanning
- Network reconnaissance
- IDS-generated alerts
- Suricata event ingestion into Wazuh

Relevant documentation:

`docs/suricata-installation.md`

`docs/suricata-configuration.md`

`docs/suricata-rules.md`

`docs/suricata-wazuh-integration.md`

---

## Troubleshooting & Operational Investigation

The lab also documents operational issues encountered while running the monitoring environment.

This includes investigation of Wazuh Indexer disk pressure and the resulting:

`read_only_allow_delete`

index block caused by the disk flood-stage watermark.

The issue was investigated from the filesystem level before modifying the Indexer configuration.

Troubleshooting documentation:

`docs/troubleshooting/`

This demonstrates that maintaining a SOC lab also requires understanding the health of the underlying telemetry and indexing pipeline.

---

## Project Structure

~~~text
wazuh-security-monitoring-lab/
│
├── configs/
│   ├── sysmon/
│   └── ...
│
├── docs/
│   ├── architecture/
│   ├── troubleshooting/
│   ├── agent-deployment.md
│   ├── custom-rules.md
│   ├── environment.md
│   ├── suricata-configuration.md
│   ├── suricata-installation.md
│   ├── suricata-rules.md
│   ├── suricata-wazuh-integration.md
│   ├── sysmon-configuration.md
│   └── wazuh-installation.md
│
├── investigations/
│   ├── incident-01-smb-authentication.md
│   ├── incident-02-smb-brute-force-detection-rule.md
│   ├── incident-03a-powershell-execution-benign.md
│   ├── incident-03b-powershell-encoded-command.md
│   ├── incident-04-temporary-directory-executable.md
│   └── incident-05-account-discovery-net-user-powershell.md
│
├── rules/
├── screenshots/
├── scripts/
│
└── README.md
~~~

---

## Skills Practiced

### SOC & Security Operations

- Alert Triage
- Security Monitoring
- Incident Investigation
- Log Analysis
- Evidence Analysis
- Detection Validation
- False Positive Assessment
- Security Event Documentation

### SIEM & Detection Engineering

- Wazuh Deployment
- Wazuh Agent Management
- Custom Detection Rules
- Windows Event Collection
- Sysmon Integration
- Suricata Integration
- IDS Alert Ingestion
- Detection Testing

### Endpoint Security

- Windows Process Analysis
- PowerShell Monitoring
- Parent-Child Process Analysis
- Command-Line Analysis
- User and Account Activity Analysis
- Sysmon Event Analysis

### Network Security

- Network Traffic Analysis
- IDS Monitoring
- Nmap Scanning
- Network Reconnaissance Detection

### Frameworks

- MITRE ATT&CK
- Incident Investigation Methodology

---

## Key Learning Outcomes

Building this environment from scratch helped me understand that a SIEM is not simply a dashboard that displays alerts.

A useful security monitoring pipeline depends on multiple layers:

**Telemetry → Collection → Detection → Alert → Investigation → Decision**

During the project, I learned to investigate alerts by examining the underlying evidence rather than relying only on the alert title or severity.

For endpoint investigations, this included analyzing:

- Process creation events
- Command lines
- Parent-child process relationships
- User context
- Sysmon telemetry
- Windows Event Logs

For network investigations, the lab provided experience with:

- Network reconnaissance
- Nmap-generated traffic
- Suricata detection
- IDS alert ingestion
- Network security telemetry

The project also demonstrated the operational side of security monitoring. When the Wazuh Indexer encountered disk pressure and indexes entered a `read_only_allow_delete` state, the problem had to be investigated at the infrastructure and storage layer rather than immediately changing detection rules.

Overall, the lab reinforced an important SOC principle:

> An alert is only the beginning of an investigation.

---

## Future Improvements

Planned improvements will focus on increasing investigation depth and detection quality rather than simply adding more tools.

Potential improvements include:

- Additional endpoint investigation scenarios
- More advanced Sysmon detection rules
- Improved Wazuh detection tuning
- Additional Suricata detection use cases
- Custom Wazuh decoders
- Active Directory monitoring
- Additional MITRE ATT&CK techniques
- Improved alert correlation
- Email-based alert notification

---

## Project Goal

The goal of this project is to build practical SOC analyst skills through a self-hosted security monitoring environment.

The emphasis is on being able to answer:

**Why did this alert fire?**

**What evidence supports the alert?**

**Is the activity benign, suspicious, or malicious?**

**What MITRE ATT&CK technique is involved?**

**What should the analyst do next?**

This project is intended as a practical demonstration of those investigation and security monitoring skills.
