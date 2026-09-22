# Wazuh Security Monitoring Lab

A hands-on SOC monitoring and security investigation lab built from the ground up to practice SIEM deployment, Windows endpoint monitoring, network intrusion detection, alert triage, log analysis, detection engineering, threat hunting, endpoint investigation, and incident documentation in a self-hosted environment.

The project focuses on understanding the analyst workflow behind security telemetry — from collection and detection to triage, investigation, evidence analysis, MITRE ATT&CK mapping, findings, and recommended response.

---

## Overview

This project started as a Wazuh-based SIEM lab for monitoring a Windows 11 endpoint.

As the lab evolved, additional telemetry, detection, and investigation capabilities were integrated:

- **Sysmon** for detailed Windows process and system telemetry
- **Suricata** for network intrusion detection
- **Kali Linux** for controlled attack simulation and network testing
- **Custom Wazuh rules** for detecting specific security behaviors
- **Velociraptor** for endpoint investigation and DFIR-oriented evidence collection
- **Mini DLP pipeline** for policy-based sensitive-data monitoring

The lab is designed around a practical SOC workflow:

**Generate activity → Collect telemetry → Detect → Triage → Investigate → Correlate evidence → Map to MITRE ATT&CK → Document findings → Recommend response**

Rather than focusing only on whether an alert was generated, the project emphasizes understanding **why the detection fired, what evidence supports it, what remains uncertain, and what an analyst should do next.**

---

## Lab Architecture

The detailed architecture documentation is available in:

`docs/architecture/`

High-level architecture:

~~~text
                         ┌──────────────────────────────┐
                         │          Ubuntu 24.04        │
                         │                              │
                         │  Wazuh Manager               │
                         │  Wazuh Dashboard             │
                         │  Wazuh Indexer               │
                         │  Filebeat                    │
                         │  Suricata                    │
                         │  Velociraptor Server         │
                         └──────────────┬───────────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                         ▼                             ▼
                ┌─────────────────┐           ┌─────────────────┐
                │    Windows 11   │           │   Kali Linux    │
                │                 │           │                 │
                │ Wazuh Agent     │           │ Attack Testing  │
                │ Sysmon          │           │ Nmap            │
                └────────┬────────┘           └────────┬────────┘
                         │                             │
                         ▼                             ▼
                 Windows Telemetry              Network Traffic
                         │                             │
                         ▼                             ▼
                      Sysmon                      Suricata
                         │                             │
                         └──────────────┬──────────────┘
                                        ▼
                                Wazuh Detection
                                        │
                                        ▼
                                  SOC Alert / Event
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                         ▼                             ▼
                   Alert Triage                 Endpoint Investigation
                         │                       with Velociraptor
                         └──────────────┬──────────────┘
                                        ▼
                              Findings / Assessment
                                        │
                                        ▼
                                  Documentation
~~~

---

## Technologies

### SIEM & Security Monitoring

- Wazuh
- Wazuh Manager
- Wazuh Indexer
- Wazuh Dashboard
- Filebeat

### Endpoint Monitoring & Investigation

- Windows 11
- Wazuh Agent
- Sysmon
- PowerShell
- Windows Event Logs
- Velociraptor

### Network Monitoring

- Suricata
- Nmap
- Kali Linux
- PCAP / network telemetry analysis

### Environment & Tooling

- Ubuntu 24.04
- Docker
- Git / GitHub
- Python

---

## Detection & Investigation Use Cases

| ID | Use Case | MITRE ATT&CK | Status |
|----|----------|---------------|:------:|
| 01 | SMB Authentication Failure Detection | — | Completed |
| 02 | SMB Brute Force Detection with Custom Rule | T1110 | Completed |
| 03a | Benign PowerShell Execution | T1059.001 | Completed |
| 03b | PowerShell Encoded Command | T1059.001 | Completed |
| 04 | Executable Dropped and Executed from Temporary Directory | Execution Context | Completed |
| 05 | Account Discovery using `net user` via PowerShell | T1087.001, T1059.001 | Completed |
| 06 | Network Reconnaissance / TCP SYN Scan | T1046 | Completed |
| 07 | Scheduled Task Execution Investigation | — | Completed |
| 08 | DNS Anomaly / DNS Query Investigation | — | Completed |
| 09 | Mini DLP Policy Violation Investigation | — | Completed |
| 10 | Endpoint Investigation / DFIR with Velociraptor | — | Completed |

The investigations are documented in:

`investigations/`

Each investigation focuses on the available telemetry, detection logic, evidence, analyst reasoning, limitations, and recommended response or next investigative action.

### Important Investigation Principle

Not every test in this lab produces a security alert.

Some investigations intentionally document:

- raw telemetry without a dedicated detection
- benign activity that triggered an alert
- false-positive analysis
- detection gaps
- negative hunting results
- limitations in available evidence

This reflects a practical SOC environment where **telemetry, alerts, and confirmed malicious activity are not interchangeable.**

---

## Investigation Workflow

The investigations in this lab follow a repeatable SOC analyst workflow.

### 1. Alert / Event Identification

Determine what triggered the investigation and identify the affected endpoint, event type, timestamp, and detection rule when applicable.

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
- Suricata events
- Endpoint artifacts collected with Velociraptor

### 4. Investigation

Correlate available evidence to understand:

- What happened?
- Which process or user initiated the activity?
- What was the parent process?
- What command was executed?
- What system or account was affected?
- What network activity was involved?
- Is there evidence of malicious intent?
- What evidence is missing?

### 5. MITRE ATT&CK Mapping

Where applicable, observed behavior is mapped to relevant MITRE ATT&CK techniques.

The mapping is treated as behavioral context rather than proof of threat-actor attribution.

### 6. Findings & Recommendation

The investigation concludes with an analyst assessment, limitations where relevant, and recommended response or next investigative action.

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
- DLP policy violations

Detection rules are stored in:

`rules/`

Supporting configuration and validation documentation are available in:

`docs/`

The lab emphasizes validating detections against actual telemetry rather than treating the rule definition itself as proof that a behavior occurred.

---

## Suricata Integration

Suricata is integrated into the lab as a network intrusion detection system.

The integration allows network activity generated during controlled testing to be observed independently from endpoint telemetry.

Example activity includes:

- Nmap scanning
- Network reconnaissance
- TCP SYN scan detection
- DNS activity analysis
- IDS-generated alerts
- Suricata event ingestion into Wazuh
- PCAP review during investigation

Relevant documentation:

- `docs/suricata-installation.md`
- `docs/suricata-configuration.md`
- `docs/suricata-rules.md`
- `docs/suricata-wazuh-integration.md`

---

## Mini DLP Investigation

The lab includes a small policy-based DLP exercise integrated with Wazuh.

The scenario uses controlled dummy files with different classifications and evaluates whether sensitive data is being copied to restricted destinations.

The pipeline is:

~~~text
Controlled File
      ↓
DLP Scanner
      ↓
Structured JSON Event
      ↓
Wazuh Agent
      ↓
Wazuh Manager
      ↓
Custom Detection Rule
      ↓
Policy Violation Alert
~~~

The investigation demonstrates how a custom security control can generate structured telemetry and feed it into the SIEM for monitoring and investigation.

The exercise intentionally uses **policy violation** terminology rather than claiming confirmed data exfiltration.

---

## Endpoint Investigation with Velociraptor

Velociraptor is integrated as a complementary endpoint investigation tool.

The workflow is:

~~~text
Wazuh Alert / Investigation Lead
              ↓
       Endpoint Question
              ↓
        Velociraptor
              ↓
      Artifact Collection
              ↓
      Evidence Analysis
              ↓
       Investigation
~~~

The completed endpoint investigation used Wazuh-detected PowerShell-related activity as the starting point and used Velociraptor to collect additional endpoint telemetry.

The case also demonstrates an important DFIR limitation:

> Historical telemetry and current filesystem state are different evidence sources.

An artifact that existed when an event occurred may no longer be present when an analyst investigates the endpoint.

---

## Troubleshooting & Operational Investigation

The lab also documents operational issues encountered while running the monitoring environment.

This includes investigation of Wazuh Indexer disk pressure and the resulting:

`read_only_allow_delete`

index block caused by the disk flood-stage watermark.

The issue was investigated from the filesystem and service level before modifying the Indexer configuration.

Troubleshooting documentation:

`docs/troubleshooting/`

This demonstrates that maintaining a SOC lab also requires understanding the health of the underlying telemetry, storage, indexing, and detection pipeline.

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
│   ├── incident-05-account-discovery-net-user-powershell.md
│   ├── incident-06-network-reconnaissance.md
│   ├── incident-07-scheduled-task.md
│   ├── incident-08-dns-anomaly.md
│   ├── incident-09-mini-dlp/
│   └── incident-10-velociraptor-endpoint-investigation/
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
- Threat Hunting
- Log Analysis
- Evidence Analysis
- Detection Validation
- False Positive Assessment
- Negative Finding Assessment
- Security Event Documentation

### SIEM & Detection Engineering

- Wazuh Deployment
- Wazuh Agent Management
- Custom Detection Rules
- Windows Event Collection
- Sysmon Integration
- Suricata Integration
- IDS Alert Ingestion
- Structured JSON Log Ingestion
- Detection Testing
- Detection Gap Analysis

### Endpoint Security & DFIR

- Windows Process Analysis
- PowerShell Monitoring
- Parent-Child Process Analysis
- Command-Line Analysis
- User and Account Activity Analysis
- Sysmon Event Analysis
- Endpoint Artifact Collection
- Velociraptor Investigation

### Network Security

- Network Traffic Analysis
- IDS Monitoring
- Nmap Scanning
- Network Reconnaissance Detection
- DNS Telemetry Analysis
- PCAP Review

### Frameworks

- MITRE ATT&CK
- Incident Investigation Methodology

---

## Key Learning Outcomes

Building this environment from scratch helped me understand that a SIEM is not simply a dashboard that displays alerts.

A useful security monitoring pipeline depends on multiple layers:

**Telemetry → Collection → Detection → Alert → Investigation → Decision**

During the project, I learned to investigate security activity by examining the underlying evidence rather than relying only on the alert title or severity.

For endpoint investigations, this included analyzing:

- Process creation events
- Command lines
- Parent-child process relationships
- User context
- Sysmon telemetry
- Windows Event Logs
- Endpoint artifacts

For network investigations, the lab provided experience with:

- Network reconnaissance
- Nmap-generated traffic
- Suricata detection
- IDS alert ingestion
- DNS activity
- Network security telemetry

The project also demonstrated that not every useful investigation begins with a high-severity alert. Some cases required examining raw telemetry, validating whether a detection was meaningful, or determining that the available evidence was insufficient to support a stronger conclusion.

The lab also reinforced the operational side of security monitoring. When the Wazuh Indexer encountered disk pressure and indexes entered a `read_only_allow_delete` state, the problem had to be investigated at the infrastructure and storage layer rather than immediately changing detection rules.

Overall, the lab reinforced an important SOC principle:

> **An alert is only the beginning of an investigation.**

---

## Future Improvements

Future work will focus on increasing investigation depth and detection quality rather than simply adding more tools.

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

**Why did this alert or event occur?**

**What evidence supports the activity?**

**Is the activity benign, suspicious, or malicious?**

**What MITRE ATT&CK technique is involved?**

**What evidence is still missing?**

**What should the analyst do next?**

This project is intended as a practical demonstration of those investigation, detection engineering, threat hunting, and security monitoring skills.
