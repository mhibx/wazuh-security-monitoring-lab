# Incident 03A - PowerShell Execution Investigation (Benign Activity)

## Overview

This investigation analyzes a normal PowerShell execution captured by Sysmon and monitored through Wazuh.

The objective of this lab is not to detect malware, but to understand how a legitimate administrative PowerShell session generates Windows telemetry, how Wazuh interprets that telemetry, and why some default detections may initially appear suspicious.

This incident demonstrates the importance of validating alerts through process correlation instead of relying solely on alert severity.

---

# Objectives

- Execute a legitimate PowerShell session
- Observe Sysmon Process Creation events
- Observe Sysmon File Creation events
- Analyze Wazuh alerts generated from the activity
- Correlate multiple events into a single timeline
- Determine whether the alert represents malicious or benign behavior

---

# Lab Environment

| Component | Value |
|-----------|------|
| SIEM | Wazuh 4.x |
| Endpoint | Windows 11 |
| Telemetry | Sysmon |
| Investigation Type | Endpoint Monitoring |
| PowerShell Version | Windows PowerShell 5.1 |

---

# Network

| Host | IP Address |
|------|-----------|
| Windows Endpoint | 192.168.1.4 |
| Wazuh Server | 192.168.1.7 |

---

# Scenario

A user launches Windows PowerShell from the Start Menu and executes a simple administrative command.

```powershell
Get-Process
```

No malicious payloads, downloads, or persistence mechanisms are used.

---

# Investigation Timeline

| Time | Event |
|------|------|
|20:57:21|PowerShell process created (Sysmon Event ID 1)|
|20:57:22|PowerShell creates temporary execution policy test file (Sysmon Event ID 11)|
|20:57:22|Wazuh Rule 92213 triggered|
|20:57:22|Wazuh Rule 92200 triggered|

---

# Event Correlation

## Step 1

Explorer launches PowerShell.

```
explorer.exe
        │
        ▼
powershell.exe
```

Sysmon records:

```
Event ID 1
Process Create
```

---

## Step 2

PowerShell initializes its execution environment.

During startup, Windows PowerShell creates a temporary script:

```
__PSScriptPolicyTest_xxxxx.ps1
```

Sysmon records:

```
Event ID 11
File Create
```

---

## Step 3

Wazuh receives the Sysmon telemetry.

The following default rules are triggered.

Rule 92213

```
Executable file dropped in folder commonly used by malware
```

Rule 92200

```
Scripting file created under Windows Temp or User folder
```

---

# Process Correlation

Parent Process

```
explorer.exe
```

↓

Child Process

```
powershell.exe
```

↓

File Created

```
__PSScriptPolicyTest_xxxxx.ps1
```

↓

Sysmon Event ID 11

↓

Wazuh Alert

---

# Investigation Findings

## Process

```
powershell.exe
```

Parent

```
explorer.exe
```

User

```
X390\tempo
```

Activity

```
Get-Process
```

Temporary File

```
__PSScriptPolicyTest_xxxxx.ps1
```

---

# Why Was an Alert Generated?

PowerShell automatically creates a temporary script named:

```
__PSScriptPolicyTest_xxxxx.ps1
```

during startup to validate the current execution policy.

The file is created inside the user's temporary directory.

Wazuh's default Sysmon detection rules identify executable-created files within temporary locations because similar behavior is commonly observed during malware execution.

The rule evaluates behavioral patterns rather than user intent.

---

# Analysis

Indicators supporting benign activity:

- PowerShell launched directly from Explorer.
- Administrative command executed (`Get-Process`).
- No encoded commands.
- No network connections.
- No persistence mechanisms.
- No suspicious child processes.
- Temporary file matches PowerShell's normal execution policy validation.

---

# Analyst Decision

Classification

```
False Positive
```

Severity Assessment

```
Low Risk
```

Escalation Required

```
No
```

Containment

```
Not Required
```

Recommendation

```
Continue monitoring PowerShell activity.

Do not suppress PowerShell alerts globally.

Future detection improvements should distinguish legitimate execution policy checks from suspicious PowerShell behavior using process lineage and command-line analysis.
```

---

# Lessons Learned

A high-severity alert does not necessarily indicate malicious activity.

Security analysts should validate:

- Parent process
- Command line
- Process correlation
- Timeline
- User context
- Subsequent behavior

before concluding that an alert represents an actual security incident.

This investigation highlights the difference between telemetry, detection, and analyst decision-making.

---

# Skills Demonstrated

- Sysmon Investigation
- Windows Event Analysis
- Event ID 1 (Process Create)
- Event ID 11 (File Create)
- Process Correlation
- Parent/Child Process Analysis
- Timeline Reconstruction
- Wazuh Alert Analysis
- False Positive Investigation
- SOC Analyst Workflow

---

# Repository Artifacts

```
investigations/
└── incident-03a-powershell-benign.md

screenshots/
└── incident-03a/

scripts/
└── (manual PowerShell execution)

rules/
└── Default Wazuh Rules
```

---

# SOC Takeaway

PowerShell is not inherently malicious. Security monitoring should focus on behavioral context—including process lineage, command-line arguments, subsequent actions, and event correlation—rather than the existence of PowerShell alone. Effective detection requires distinguishing legitimate administrative activity from attacker behavior.
