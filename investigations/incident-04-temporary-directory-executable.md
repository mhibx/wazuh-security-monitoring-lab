# Incident 04 — Executable Dropped and Executed from Temp Directory

## Overview

This investigation simulates a benign executable being copied into a Windows temporary directory and then executed.

For the simulation, a copy of the legitimate `notepad.exe` executable was renamed to `normalfile2.exe` and placed in the user's `%TEMP%` directory.

The investigation focuses on three stages of endpoint activity:

1. Executable file creation
2. Process execution
3. Process termination

The main objective is to understand how Sysmon provides endpoint telemetry and how Wazuh determines which telemetry should become a security alert.

An important observation from this investigation is that **telemetry does not automatically become a SIEM alert**. Sysmon can record an event while Wazuh may not generate a corresponding high-level alert unless a detection rule matches that activity.

---

## Objectives

- Simulate an executable being copied into a temporary directory.
- Observe Sysmon Event ID 11 (FileCreate).
- Observe Sysmon Event ID 1 (Process Create).
- Observe Sysmon Event ID 5 (Process Terminated).
- Investigate which events generate Wazuh alerts.
- Compare raw endpoint telemetry with SIEM detection alerts.
- Understand how Wazuh detection rules determine which events require analyst attention.
- Identify opportunities for future event correlation and detection engineering.

---

## Lab Environment

| Component | Details |
|---|---|
| Endpoint | Windows 11 — ThinkPad X390 |
| Endpoint IP | `192.168.1.4` |
| SIEM | Wazuh |
| Monitoring | Sysmon |
| SIEM Interface | Wazuh Dashboard / OpenSearch |
| User Context | `X390\tempo` |

---

## Activity Simulation

A legitimate copy of `notepad.exe` was copied into the Windows temporary directory and renamed to `normalfile2.exe`.

### Original File

```text
C:\Windows\System32\notepad.exe
```

### Destination

```text
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe
```

### PowerShell Commands

```powershell
Copy-Item "$env:WINDIR\System32\notepad.exe" "$env:TEMP\normalfile2.exe"
Start-Process "$env:TEMP\normalfile2.exe"
```

The executable itself was benign. The purpose was to generate realistic endpoint telemetry for detection and investigation.

---

## Detection Flow

```text
PowerShell
    │
    ├── Copy-Item notepad.exe → %TEMP%\normalfile2.exe
    │
    ▼
Sysmon Event ID 11
    │
    ▼
Wazuh Rule 92213
    │
    ▼
Executable file created in a directory commonly used by malware
    │
    │
    └── Start-Process normalfile2.exe
              │
              ▼
       Sysmon Event ID 1
       Process Create
              │
              ▼
       Sysmon Event ID 5
       Process Terminated
```

---

## Investigation Timeline

The activity produced the following sequence:

```text
PowerShell Copy-Item
        │
        ▼
Sysmon Event ID 11 — FileCreate
        │
        ▼
Wazuh Rule 92213 — Alert
        │
        ▼
PowerShell Start-Process
        │
        ▼
Sysmon Event ID 1 — Process Create
        │
        ▼
Sysmon Event ID 5 — Process Terminated
```

This timeline demonstrates that multiple endpoint events can describe different stages of the same activity.

---

## Sysmon Event ID 11 — File Creation

The first important event was Sysmon Event ID 11 (`FileCreate`).

The event recorded the creation of:

```text
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe
```

Relevant telemetry included:

| Field | Value |
|---|---|
| Event ID | 11 |
| RuleName | `EXE` |
| Image | PowerShell |
| TargetFilename | `%TEMP%\normalfile2.exe` |
| User | `X390\tempo` |

Wazuh generated an alert through Rule `92213`.

### Wazuh Rule 92213

```text
Rule ID: 92213
Level: 15
Description: Executable file dropped in folder commonly used by malware
MITRE Mapping: T1105
```

The MITRE ATT&CK mapping above belongs to the Wazuh detection rule. It should not be interpreted as an analyst conclusion that the simulated activity itself constituted a confirmed `T1105` technique.

The activity was intentionally benign and used only to generate telemetry.

---

## Sysmon Event ID 1 — Process Creation

After the file was created, `normalfile2.exe` was executed.

Sysmon Event ID 1 recorded the process creation.

Relevant information included:

| Field | Value |
|---|---|
| Event ID | 1 |
| Image | `%TEMP%\normalfile2.exe` |
| OriginalFileName | `NOTEPAD.EXE` |
| Description | Notepad |
| ParentImage | PowerShell |
| User | `X390\tempo` |

The `OriginalFileName` and file description helped establish that the executable was actually a renamed copy of the legitimate Windows Notepad executable.

Although the process creation event was visible in endpoint telemetry, there was no equivalent high-level Wazuh alert for this specific event in this investigation.

---

## Sysmon Event ID 5 — Process Termination

After execution, Sysmon generated Event ID 5 (`Process Terminated`) for the process.

This provided additional information about the lifecycle of the executable.

However, similar to Event ID 1, there was no equivalent high-level Wazuh alert for this event in this investigation.

This demonstrates that endpoint telemetry can contain considerably more information than what is surfaced as SIEM alerts.

---

## Telemetry vs Detection

One of the main lessons from this investigation is the distinction between **telemetry** and **detection**.

| Event | Sysmon Telemetry | Wazuh Alert |
|---|---:|---:|
| Event ID 11 — FileCreate | Yes | Yes — Rule 92213 |
| Event ID 1 — Process Create | Yes | No equivalent high-level alert |
| Event ID 5 — Process Terminated | Yes | No equivalent high-level alert |

Sysmon provides the underlying endpoint telemetry.

Wazuh then evaluates incoming events against its detection rules. Only events that match relevant rules become alerts requiring further analyst attention.

Therefore:

```text
Telemetry ≠ Alert
```

An event being collected does not necessarily mean that Wazuh considers it suspicious enough to generate an alert.

---

## Detection Engineering Perspective

The individual Event ID 11 alert provides useful context because executable creation inside a temporary directory can be associated with malicious activity.

However, the context becomes more interesting when multiple events are considered together:

```text
PowerShell
    ↓
Executable created in %TEMP%
    ↓
Executable executed
    ↓
Process activity
```

A future detection could correlate these events to increase confidence.

For example:

```text
PowerShell creates executable in %TEMP%
        +
Same executable is subsequently executed
        +
Additional suspicious behavior
        ↓
Higher-confidence detection
```

This would reduce reliance on a single event and allow the detection logic to consider the broader process timeline.

---

## Analyst Assessment

Although the behavior resembles a pattern that can occur during malware execution, the simulated activity was benign.

The executable was:

- A copy of the legitimate Windows `notepad.exe`.
- Renamed to `normalfile2.exe`.
- Intentionally placed in `%TEMP%`.
- Intentionally executed to generate Sysmon telemetry.

There was no evidence in this investigation of:

- Malware execution
- Persistence
- Credential theft
- Command-and-control activity
- Exploitation
- Malicious payload delivery

The Wazuh alert therefore demonstrates **detection of suspicious-looking behavior**, not confirmation of compromise.

---

## Key Findings

### 1. Sysmon provides detailed endpoint telemetry

Sysmon captured multiple stages of the activity:

- File creation
- Process creation
- Process termination

### 2. Wazuh does not alert on every event

Only Event ID 11 generated a corresponding high-level Wazuh alert through Rule `92213`.

### 3. Detection rules determine analyst visibility

Raw telemetry can exist without generating a SIEM alert.

This highlights the role of detection engineering in determining which events should be surfaced and at what severity.

### 4. Context is required

An executable inside `%TEMP%` can be suspicious, but the location alone does not prove malicious activity.

Process lineage, file metadata, user context, command line, network activity, and subsequent behavior should be considered during investigation.

### 5. Correlation can increase detection confidence

Combining file creation and process execution events could produce a stronger detection than relying on either event independently.

---

## Lessons Learned

This investigation reinforced several important SOC concepts:

- Telemetry and alerts are not the same thing.
- A detection rule determines whether telemetry becomes an alert.
- File creation and process execution should be investigated as part of a timeline.
- File metadata can provide useful context during endpoint investigations.
- Suspicious behavior does not automatically mean compromise.
- Detection quality can be improved by correlating multiple related events.
- Analysts should distinguish between what the telemetry proves and what it merely suggests.

---

## Evidence

Screenshots and investigation evidence:

```text
screenshots/incident-04/
```

Relevant evidence includes:

- Sysmon Event ID 11 showing executable creation.
- Wazuh Rule 92213 alert.
- Sysmon Event ID 1 showing process creation.
- Sysmon Event ID 5 showing process termination.
- Timeline showing the relationship between the events.

---

## Repository Artifacts

```text
investigations/
└── incident-04-executable-temp/
    └── README.md

screenshots/
└── incident-04/
```

---

## MITRE ATT&CK Context

Wazuh Rule `92213` contains a MITRE ATT&CK mapping to:

```text
T1105 — Ingress Tool Transfer
```

This mapping represents the technique associated with the existing Wazuh detection rule.

It should not be interpreted as a claim that the benign simulation itself demonstrated a confirmed `T1105` intrusion technique.

---

## Conclusion

This investigation demonstrated how a simple executable file operation can generate multiple layers of endpoint telemetry.

Sysmon recorded the creation, execution, and termination of the executable, while Wazuh surfaced the file creation event through Rule `92213`.

The most important takeaway is the distinction between **collecting telemetry** and **generating detections**. A mature SOC cannot rely only on raw events; it needs detection logic that identifies meaningful patterns and provides enough context for analysts to determine whether activity is benign or suspicious.

This case also provides a foundation for future detection engineering work, particularly around correlating executable creation with subsequent process execution and other suspicious behaviors.

---

## Status

**Investigation Completed**
