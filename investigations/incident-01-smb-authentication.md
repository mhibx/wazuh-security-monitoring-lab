# Incident 01 — SMB Authentication Failure Detection with Wazuh

## Overview

This investigation demonstrates how Wazuh can detect and investigate a failed SMB authentication attempt against a Windows endpoint.

The scenario simulates an authentication attempt from a Kali Linux machine using an invalid account. The Windows endpoint records the failed authentication as Security Event ID 4625, which is then collected by the Wazuh Agent and surfaced as a security alert.

The main focus of this exercise was not simply generating an alert, but following the event through the monitoring pipeline and validating the available evidence during the investigation.

---

## Objectives

- Simulate a failed SMB authentication attempt from Kali Linux
- Generate Windows Security Event ID 4625
- Verify that the Wazuh Agent collects the event
- Investigate the resulting Wazuh alert
- Trace the activity from the attacker machine to the SIEM
- Understand how NAT affects source IP visibility
- Evaluate different tools for generating repeated SMB authentication attempts

---

## Lab Architecture

~~~text
                         +----------------------+
                         |    Kali Linux VM     |
                         | 192.168.122.64       |
                         |                      |
                         | SMB Client           |
                         +----------+-----------+
                                    |
                                    | libvirt NAT
                                    ▼
                         +----------------------+
                         |    Ubuntu Host       |
                         | 192.168.1.7          |
                         |                      |
                         | Wazuh Manager        |
                         | Wazuh Dashboard      |
                         | Suricata             |
                         +----------+-----------+
                                    |
                                    | LAN
                                    ▼
                         +----------------------+
                         |   Windows 11         |
                         | 192.168.1.4          |
                         |                      |
                         | Wazuh Agent          |
                         | Sysmon               |
                         +----------------------+
~~~

### Network Consideration

The Kali Linux VM uses libvirt NAT networking.

Although the authentication attempt originates from Kali (`192.168.122.64`), the Windows endpoint observes the connection as originating from the Ubuntu host (`192.168.1.7`), which acts as the NAT gateway.

This explains why Windows Security Event 4625 records `192.168.1.7` as the source IP while identifying the workstation as `KALI-ATTACKER`.

This distinction is important during investigation because the source IP visible in endpoint telemetry does not always represent the original system that initiated the activity.

---

## Environment

| Component | Value |
|-----------|-------|
| SIEM | Wazuh 4.x |
| Manager OS | Ubuntu |
| Endpoint | Windows 11 |
| Attacker | Kali Linux |
| Protocol | SMB |
| Windows Event | 4625 |
| Authentication | NTLM |
| Kali IP | 192.168.122.64 |
| Ubuntu IP | 192.168.1.7 |
| Windows IP | 192.168.1.4 |

---

## Attack Scenario

The simulated attacker attempts to authenticate to the Windows SMB service using a non-existent account.

The Windows endpoint rejects the authentication request and records Security Event ID 4625.

The Wazuh Agent forwards the event to the Wazuh Manager, where Rule ID 60122 identifies the failed authentication.

The investigation then uses both Windows Event Viewer and Wazuh to validate the event and understand the authentication failure.

---

# Attack Simulation

## Step 1 — Verify SMB Service

The first step was to verify that the SMB service was reachable from the attacker machine.

~~~bash
nmap -Pn -p445 192.168.1.4
~~~

Result:

- TCP/445 was open.

---

## Step 2 — Attempt SMB Authentication

A failed authentication attempt was generated using `smbclient` with an invalid username.

~~~bash
smbclient -L //192.168.1.4 -U kali-attacker
~~~

![Attacker Terminal](../screenshots/smbrute-01-single-kaliterminal.png)

Result:

~~~text
NT_STATUS_LOGON_FAILURE
~~~

The failed authentication generated Windows Security Event ID 4625.

---

# Detection

Wazuh generated Rule ID **60122** for the failed authentication.

| Item | Value |
|------|-------|
| Rule ID | 60122 |
| Description | Logon Failure - Unknown user or bad password |

![Wazuh Discover](../screenshots/smbrute-04-single-wazuhdiscover.png)

The alert confirmed that the failed authentication attempt had successfully passed through the monitoring pipeline.

---

# Investigation

## Windows Event Viewer

The corresponding Windows Security event was reviewed to understand the authentication failure in more detail.

| Field | Value |
|-------|-------|
| Event ID | 4625 |
| Log | Security |
| Authentication | NTLM |
| Source IP | 192.168.1.7 |
| Workstation | KALI-ATTACKER |
| Target User | kali-attacker |
| Failure Reason | Unknown user name or bad password |
| Status | 0xC000006D |
| SubStatus | 0xC0000064 |

![Event Viewer 1](../screenshots/smbrute-02-single-eventview.png)

![Event Viewer 2](../screenshots/smbrute-03-single-eventview.png)

These fields provided additional context beyond the Wazuh alert itself, including the authentication package, workstation name, target username, and reason for the failure.

### Source IP Analysis

The source IP recorded by Windows was `192.168.1.7`, which corresponds to the Ubuntu host rather than the Kali VM.

This is expected because the Kali VM is connected through libvirt NAT. The Ubuntu host performs the network address translation before the traffic reaches the Windows endpoint.

The workstation field, `KALI-ATTACKER`, provides additional context linking the authentication attempt to the Kali-based test environment.

This demonstrates why a SOC analyst should avoid interpreting a source IP in isolation and should consider the surrounding network topology and other available telemetry.

---

## Wazuh Alert Analysis

The corresponding Wazuh alert contained the following information:

| Field | Value |
|-------|-------|
| Agent | X390 |
| Event ID | 4625 |
| Rule ID | 60122 |
| Authentication | NTLM |
| Source IP | 192.168.1.7 |
| Workstation | KALI-ATTACKER |
| Username | kali-attacker |

![Wazuh Detail 1](../screenshots/smbrute-05-single-wazuhdetail1.png)

![Wazuh Detail 2](../screenshots/smbrute-06-single-wazuhdetail2.png)

The Wazuh alert and the Windows event provided consistent evidence that the authentication attempt had failed and allowed the activity to be investigated from the SIEM.

---

# Attack Timeline

~~~text
Kali Linux
192.168.122.64
    │
    │ SMB Authentication Attempt
    ▼
libvirt NAT
    │
    ▼
Ubuntu Host
192.168.1.7
    │
    │ Translated Network Connection
    ▼
Windows 11
192.168.1.4
    │
    ▼
Windows Security Event 4625
    │
    ▼
Wazuh Agent
    │
    ▼
Wazuh Manager
    │
    ▼
Rule 60122 Triggered
    │
    ▼
SOC Investigation
~~~

---

# MITRE ATT&CK

This investigation demonstrates a single failed SMB authentication attempt.

A single failed authentication event alone is not sufficient to claim a brute-force attack.

Potential ATT&CK mapping for repeated authentication activity includes:

- **T1110 — Brute Force**
- **TA0006 — Credential Access**

However, T1110 will be mapped to a subsequent investigation only when repeated authentication attempts are successfully simulated and detected.

This distinction prevents the investigation from overstating what the available evidence demonstrates.

---

# Findings

The investigation confirmed that:

- SMB was reachable from the attacker machine.
- An invalid SMB authentication attempt generated Windows Security Event ID 4625.
- The Wazuh Agent successfully collected the event.
- Wazuh Rule 60122 detected the failed authentication.
- The alert contained useful investigation context, including the source IP, workstation name, authentication package, and username.
- Windows Event Viewer provided additional details about the authentication failure.
- The source IP observed by Windows was the Ubuntu NAT gateway (`192.168.1.7`) rather than the Kali VM address (`192.168.122.64`).
- The workstation information provided additional context for identifying the originating test system.

---

# Investigation Notes

During the lab, multiple SMB clients were evaluated to determine whether they could be used to generate repeated failed authentication attempts.

## smbclient

`smbclient` successfully initiated an SMB authentication request using an invalid username.

The attempt generated:

- Windows Security Event ID 4625
- Wazuh Rule ID 60122
- Logon Type 3 (Network Logon)

This became the primary method used to validate the SIEM detection pipeline.

## Hydra

Hydra was tested as a way to automate SMB password-guessing attempts.

However, it returned:

~~~text
[ERROR] invalid reply from target smb://192.168.1.4:445/
~~~

![Hydra Fail](../screenshots/smbrute-01-fail-hydra.png)

No repeated authentication events were generated through this method.

## NetExec

NetExec was able to fingerprint the target and identified:

- Windows 11 Build 26100
- SMB Signing Enabled
- SMBv1 Disabled

However, the authentication process failed with:

~~~text
Connection Error:
The NETBIOS connection with the remote host timed out
~~~

![Netexec Fail](../screenshots/smbrute-02-fail-netexec.png)

The Windows SMB Server logs recorded additional events:

- Event ID 551 — Smb2SessionAuthFailure
- Event ID 1009 — SrvSessionAnonymousAccessDenied

![SMB Event Viewer](../screenshots/smbrute-03-fail-eventview.png)

The authentication session terminated before username validation, preventing repeated Event ID 4625 entries from being generated.

Further investigation may be required to determine whether this behavior is related to compatibility between NetExec/Hydra and the Windows 11 Build 26100 SMB implementation.

---

# Lessons Learned

This investigation provided practical experience with the relationship between endpoint telemetry and SIEM detection.

Key takeaways include:

- A successful TCP connection to SMB does not guarantee a successful authentication session.
- Windows can record authentication failures across multiple logging channels.
- Security Event ID 4625 provides useful information for investigating failed authentication attempts.
- Windows Security logs and Microsoft-Windows-SMBServer logs can provide complementary evidence.
- NAT can cause the source IP observed by an endpoint to differ from the original attacker's IP.
- Source IP should be interpreted together with workstation, username, authentication type, and network topology.
- Different authentication tools may interact with modern Windows SMB implementations differently.
- Troubleshooting an unsuccessful attack simulation is also part of security engineering.
- A SOC investigation should validate assumptions using multiple sources rather than relying on a single tool or alert.

---

# Future Improvements

- Correlate repeated Windows Security Event 4625 events into a higher-confidence authentication attack detection.
- Investigate controlled password spraying and brute-force patterns.
- Improve visualization of authentication failures using Wazuh dashboards.
- Correlate Windows Security Event 4625 with SMB Server events where appropriate.

---

# Repository Status

**Current Status: Baseline Detection Completed**

- SMB connectivity verified
- Failed SMB authentication successfully simulated
- Windows Security Event ID 4625 collected
- Wazuh Rule 60122 validated
- Investigation evidence documented
- NAT behavior analyzed
- Multiple SMB authentication tools evaluated

Advanced attack simulation, including password spraying and brute-force scenarios, remains planned for a future iteration.
