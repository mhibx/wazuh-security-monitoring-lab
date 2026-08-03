# Incident 01 - SMB Authentication Failure Detection with Wazuh

## Overview

This project demonstrates how Wazuh detects and investigates a failed SMB authentication attempt against a Windows endpoint.

The objective is to simulate an authentication failure from an attacker machine, collect Windows Security Event logs, and investigate how Wazuh parses and generates security alerts.

---

## Objectives

- Simulate an SMB authentication attempt from Kali Linux
- Generate Windows Security Event ID 4625
- Verify log collection by Wazuh Agent
- Investigate the generated alert inside Wazuh
- Understand the attack flow from attacker to SIEM

---

# Lab Architecture

```
                    +----------------------+
                    |    Kali Linux VM     |
                    | 192.168.122.64       |
                    +----------+-----------+
                               |
                     SMB Authentication
                               |
                               |
                               ▼
                    +----------------------+
                    | Windows 10 Endpoint  |
                    | 192.168.1.4          |
                    | Wazuh Agent          |
                    +----------+-----------+
                               |
                         Security Event
                         Event ID 4625
                               |
                               ▼
                    +----------------------+
                    | Wazuh Manager         |
                    | Ubuntu               |
                    | 192.168.1.7          |
                    +----------------------+
```

---

# Environment

| Component | Value |
|-----------|-------|
| SIEM | Wazuh 4.x |
| Manager OS | Ubuntu |
| Endpoint | Windows 10 |
| Attacker | Kali Linux |
| Protocol | SMB |
| Windows Event | 4625 |
| Authentication | NTLM |

---

# Attack Scenario

An attacker attempts to authenticate to the SMB service using a non-existent account.

The Windows endpoint rejects the authentication request and records Security Event ID 4625.

Wazuh receives the event through the Windows agent and generates a security alert.

---

# Attack Simulation

## Step 1 — Verify SMB Service

```bash
nmap -Pn -p445 192.168.1.4
```

Result

- TCP/445 is open

Screenshot

```
screenshots/02-kali-smb-authentication.png
```

---

## Step 2 — Failed SMB Authentication

```bash
smbclient -L //192.168.1.4 -U kali-attacker
```

Result

```
NT_STATUS_LOGON_FAILURE
```

This authentication attempt generates Windows Security Event ID 4625.

---

# Detection

Wazuh successfully generated Rule ID **60122**.

Rule Information

| Item | Value |
|------|-------|
| Rule ID | 60122 |
| Description | Logon Failure - Unknown user or bad password |
| Severity | 5 |

Screenshot

```
screenshots/03-wazuh-discover-alert.png
```

---

# Investigation

## Windows Event Viewer

Event ID

```
4625
```

Log Type

```
Security
```

Authentication

```
NTLM
```

Source IP

```
192.168.1.7
```

Workstation

```
KALI-ATTACKER
```

Target User

```
kali-attacker
```

Failure Reason

```
Unknown user name or bad password
```

Status

```
0xC000006D
```

SubStatus

```
0xC0000064
```

Screenshots

```
screenshots/05-eventviewer-general.png

screenshots/06-eventviewer-details.png
```

---

## Wazuh Alert Analysis

Alert Information

| Field | Value |
|--------|-------|
| Agent | X390 |
| Event ID | 4625 |
| Rule ID | 60122 |
| Authentication | NTLM |
| Source IP | 192.168.1.7 |
| Workstation | KALI-ATTACKER |
| Username | kali-attacker |

Screenshots

```
screenshots/04-wazuh-alert-details.png
```

---

# Attack Timeline

```
Kali Linux

↓

SMB Authentication

↓

Windows Security Event 4625

↓

Wazuh Agent

↓

Wazuh Manager

↓

Rule 60122 Triggered

↓

SOC Investigation
```

---

# MITRE ATT&CK

Although this activity only simulates an authentication failure, it resembles the early phase of password guessing or brute-force attacks.

Potential ATT&CK Mapping

- T1110 – Brute Force *(future enhancement)*
- TA0006 – Credential Access

> Note:
>
> Wazuh's default rule maps Event ID 4625 differently. This lab uses the attack scenario as an educational example. Custom MITRE mapping will be implemented in future detection engineering exercises.

---

# Findings

- SMB service was reachable from the attacker machine.
- Windows successfully generated Security Event ID 4625.
- Wazuh Agent forwarded the event to the manager.
- Wazuh Rule 60122 detected the failed authentication.
- Investigation successfully identified:
  - Source IP
  - Workstation name
  - Authentication package
  - Target username
  - Failure reason

---

# Lessons Learned

Through this lab I learned how to:

- Simulate SMB authentication failures
- Investigate Windows Event ID 4625
- Correlate Windows Security logs with Wazuh alerts
- Understand the relationship between Windows Event Viewer and SIEM
- Perform basic SOC-style investigation

---

# Future Improvements

- Simulate SMB brute-force using Hydra
- Create custom Wazuh correlation rules
- Generate higher severity alerts after multiple failed logins
- Integrate Sigma rules
- Automate incident response using Active Response

