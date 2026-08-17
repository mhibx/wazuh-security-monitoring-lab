# Incident 03A — PowerShell Execution Investigation (Benign Activity)

## Overview

This investigation examines a legitimate PowerShell execution captured by Sysmon and monitored through Wazuh.

The purpose of this exercise is not to detect malware, but to understand how normal administrative activity generates Windows telemetry and how that telemetry is interpreted by a SIEM.

The investigation also demonstrates why an alert should not be assessed solely by its severity. Multiple events need to be correlated with process lineage, command-line activity, user context, and subsequent behavior before determining whether the activity is malicious.

---

## Objectives

- Execute a legitimate PowerShell session
- Observe Sysmon Process Creation events
- Observe Sysmon File Creation events
- Analyze Wazuh alerts generated from the activity
- Correlate multiple events into a single timeline
- Determine whether the detected activity is malicious or benign
- Practice false-positive analysis from a SOC analyst perspective

---

## Lab Environment

| Component | Value |
|-----------|-------|
| SIEM | Wazuh 4.x |
| Endpoint | Windows 11 |
| Telemetry | Sysmon |
| Investigation Type | Endpoint Monitoring |
| PowerShell Version | Windows PowerShell 5.1 |

---

## Network

| Host | IP Address |
|------|------------|
| Windows Endpoint | 192.168.1.4 |
| Wazuh Server | 192.168.1.7 |

---

# Scenario

A user launches Windows PowerShell from the Start Menu and executes a simple administrative command:

~~~powershell
Get-Process
~~~

No malicious payloads, downloads, persistence mechanisms, or other intentional attack activity are introduced during the simulation.

The purpose is to observe what normal PowerShell startup looks like from the perspective of endpoint telemetry.

---

# Investigation Timeline

| Time | Event |
|------|-------|
| 20:57:21 | PowerShell process created (Sysmon Event ID 1) |
| 20:57:22 | PowerShell creates temporary execution policy test file (Sysmon Event ID 11) |
| 20:57:22 | Wazuh Rule 92213 triggered |
| 20:57:22 | Wazuh Rule 92200 triggered |

---

# Event Correlation

## Step 1 — PowerShell Process Creation

Windows Explorer launches PowerShell.

~~~text
explorer.exe
      │
      ▼
powershell.exe
~~~

Sysmon records the process creation as:

~~~text
Event ID 1
Process Create
~~~

### Evidence

![Sysmon Process Creation](screenshots/incident-03a/sysmon-process-create.png)

---

## Step 2 — PowerShell Creates a Temporary File

During startup, Windows PowerShell creates a temporary script used for execution policy validation:

~~~text
__PSScriptPolicyTest_xxxxx.ps1
~~~

Sysmon records the file creation as:

~~~text
Event ID 11
File Create
~~~

### Evidence

![Sysmon File Creation](screenshots/incident-03a/sysmon-file-create.png)

---

## Step 3 — Wazuh Processes the Telemetry

Wazuh receives the Sysmon events and triggers two default detection rules.

### Rule 92213

~~~text
Executable file dropped in folder commonly used by malware
~~~

### Rule 92200

~~~text
Scripting file created under Windows Temp or User folder
~~~

### Evidence

![Wazuh Alerts](screenshots/incident-03a/wazuh-alerts.png)

The alerts indicate that the observed file-creation behavior matches patterns that can also occur during malicious activity.

At this stage, however, the alerts alone are not sufficient to classify the activity as malicious.

---

# Process Correlation

The events can be correlated into the following sequence:

~~~text
explorer.exe
    │
    ▼
powershell.exe
    │
    ▼
__PSScriptPolicyTest_xxxxx.ps1
    │
    ▼
Sysmon Event ID 11
    │
    ▼
Wazuh Detection
~~~

This process lineage provides important context for determining whether the activity is consistent with normal PowerShell behavior.

---

# Investigation Findings

## Process Context

| Field | Value |
|-------|-------|
| Process | powershell.exe |
| Parent Process | explorer.exe |
| User | X390\tempo |
| Activity | Get-Process |
| Temporary File | __PSScriptPolicyTest_xxxxx.ps1 |

### Evidence

![Process Details](screenshots/incident-03a/process-details.png)

---

# Why Was an Alert Generated?

PowerShell creates a temporary script named:

~~~text
__PSScriptPolicyTest_xxxxx.ps1
~~~

during startup to validate the current execution policy.

The file is created inside the user's temporary directory.

Wazuh's default Sysmon detection rules identify executable and scripting files created in temporary locations because similar behavior can occur during malware execution.

The detection therefore evaluates a **behavioral pattern**, rather than determining the user's intent.

This is an important distinction during security investigations: the presence of an alert indicates that a detection condition was met, not that malicious activity has been confirmed.

---

# Analysis

Several indicators support a benign classification:

- PowerShell was launched directly from Explorer.
- The executed command was `Get-Process`.
- No encoded commands were observed.
- No network connections were observed.
- No persistence mechanisms were identified.
- No suspicious child processes were observed.
- The temporary file matched the observed PowerShell execution policy validation behavior.
- The available process lineage was consistent with a normal interactive PowerShell session.

### Evidence

![PowerShell Activity](screenshots/incident-03a/powershell-activity.png)

---

# Analyst Decision

| Decision | Assessment |
|----------|------------|
| Classification | False Positive |
| Severity Assessment | Low Risk |
| Escalation Required | No |
| Containment Required | No |

### Recommendation

Continue monitoring PowerShell activity rather than suppressing PowerShell-related detections globally.

Future detection improvements should distinguish legitimate PowerShell execution from suspicious behavior by incorporating additional context such as:

- Process lineage
- Command-line arguments
- User context
- Child processes
- Network activity
- Subsequent file or registry activity

---

# Lessons Learned

This investigation reinforced that a high-severity alert does not automatically represent malicious activity.

Before escalating an alert, an analyst should validate the surrounding context, including:

- Parent process
- Command line
- Process lineage
- Timeline
- User context
- Subsequent behavior

The investigation also demonstrated the difference between **telemetry, detection, and analyst decision-making**.

Sysmon provided the underlying endpoint telemetry, Wazuh identified activity matching detection rules, and the analyst was responsible for correlating the events and determining whether the behavior represented a genuine security incident.

---

# Skills Demonstrated

- Sysmon Investigation
- Windows Event Analysis
- Event ID 1 — Process Create
- Event ID 11 — File Create
- Process Correlation
- Parent/Child Process Analysis
- Timeline Reconstruction
- Wazuh Alert Analysis
- False Positive Investigation
- SOC Analyst Workflow

---

# Repository Artifacts

~~~text
investigations/
└── incident-03a-powershell-benign.md

screenshots/
└── incident-03a/
    ├── sysmon-process-create.png
    ├── sysmon-file-create.png
    ├── wazuh-alerts.png
    ├── process-details.png
    └── powershell-activity.png

scripts/
└── (manual PowerShell execution)

rules/
└── Default Wazuh Rules
~~~

---

# SOC Takeaway

PowerShell itself is not inherently malicious.

Effective PowerShell monitoring requires looking at the surrounding behavior, including process lineage, command-line arguments, user context, network activity, child processes, and subsequent actions.

This investigation demonstrates why security monitoring should combine automated detection with contextual analysis rather than treating every PowerShell-related alert as malicious.
