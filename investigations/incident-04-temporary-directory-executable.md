# Incident 4 – Executable Dropped and Executed from Temp Directory

## Overview

This incident simulates a suspicious executable being copied into a Windows user's temporary directory and subsequently executed.

The objective is to investigate how Wazuh and Sysmon handle:

* Executable file creation
* Process execution
* Process termination
* Detection rules
* The difference between collected telemetry and generated alerts

This scenario intentionally uses a benign Windows executable (`notepad.exe`) renamed to `normalfile2.exe` so the activity can be safely reproduced in a controlled lab environment.

---

## Lab Environment

| Component   | Details                      |
| ----------- | ---------------------------- |
| Endpoint    | Windows                      |
| Hostname    | X390                         |
| Endpoint IP | 192.168.1.4                  |
| SIEM        | Wazuh                        |
| Telemetry   | Sysmon                       |
| Dashboard   | Wazuh Dashboard / OpenSearch |
| Test User   | X390\tempo                   |

---

## Attack Simulation

The simulation copies the legitimate Windows Notepad executable into the user's temporary directory under a different filename.

### Step 1 – Copy the executable

```powershell
Copy-Item "$env:WINDIR\System32\notepad.exe" "$env:TEMP\normalfile2.exe"
```

This creates:

```text
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe
```

The original executable is:

```text
C:\Windows\System32\notepad.exe
```

The file is therefore a benign executable masquerading under a different filename and located in a directory commonly abused by malware.

---

### Step 2 – Execute the copied executable

```powershell
Start-Process "$env:TEMP\normalfile2.exe"
```

The executable was successfully started and subsequently terminated.

---

# Detection Timeline

The activity generated several Sysmon events.

## 1. Sysmon Event ID 11 – File Create

The first important detection was the creation of the executable.

Observed event:

```text
Event ID: 11
RuleName: EXE
Image:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

TargetFilename:
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe

User:
X390\tempo
```

Wazuh successfully generated an alert for this activity.

### Wazuh Rule

```text
Rule ID: 92213
Rule Level: 15
Description:
Executable file dropped in folder commonly used by malware
```

MITRE ATT&CK mapping:

```text
Tactic:
Command and Control

Technique:
T1105 – Ingress Tool Transfer
```

This was the primary alert generated during the simulation.

---

## 2. Sysmon Event ID 1 – Process Create

The executable was subsequently executed.

Observed telemetry:

```text
Event ID: 1
Image:
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe

OriginalFileName:
NOTEPAD.EXE

Description:
Notepad

ParentImage:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

User:
X390\tempo
```

The event confirms that `normalfile2.exe` was executed.

However, this event did **not** appear as a separate Wazuh alert comparable to the Event ID 11 detection.

The event was visible when the dashboard was examined using an absolute timeline around the execution timestamp.

---

## 3. Sysmon Event ID 5 – Process Terminate

After execution, Sysmon also recorded the process termination.

Observed telemetry:

```text
Event ID: 5
Image:
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe
```

Like Event ID 1, the process termination was available as telemetry but did not produce the same high-level Wazuh alert as Event ID 11.

---

# Timeline

The relevant execution sequence was approximately:

```text
PowerShell
    |
    | Copy-Item
    v
normalfile2.exe created
    |
    | Sysmon Event ID 11
    v
Wazuh Rule 92213
    |
    | Start-Process
    v
normalfile2.exe executed
    |
    | Sysmon Event ID 1
    v
Process runs
    |
    | Sysmon Event ID 5
    v
Process terminates
```

The observed timestamps showed that the process execution and termination happened within only a few seconds.

---

# Investigation

## Why did Event ID 11 generate an alert?

The file was created as an executable inside a temporary directory:

```text
C:\Users\tempo\AppData\Local\Temp\
```

This combination is suspicious because temporary directories are frequently used by malware and other tools to stage executable files.

Wazuh's existing detection rule recognized this behavior and generated:

```text
Rule ID: 92213
Level: 15
```

---

## Why did Event ID 1 not generate the same alert?

This experiment demonstrated an important distinction between **telemetry collection** and **detection**.

Sysmon generated Event ID 1 containing information about the process creation.

The telemetry included:

```text
Image:
C:\Users\tempo\AppData\Local\Temp\normalfile2.exe

ParentImage:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

However, the existence of telemetry does not automatically mean that Wazuh will create a high-level alert.

The event must match an applicable Wazuh detection rule before it becomes an alert.

Therefore:

```text
Sysmon Event
      |
      v
Wazuh receives telemetry
      |
      +---- No matching detection rule
      |          |
      |          v
      |      No alert
      |
      +---- Matching detection rule
                 |
                 v
               Alert
```

---

# Important Finding

This incident demonstrated that **not every piece of telemetry becomes an alert**.

The lab produced the following distinction:

| Activity                   |      Sysmon |                             Wazuh Alert |
| -------------------------- | ----------: | --------------------------------------: |
| Executable created in Temp | Event ID 11 |                        Yes – Rule 92213 |
| Executable executed        |  Event ID 1 | No equivalent high-level alert observed |
| Executable terminated      |  Event ID 5 | No equivalent high-level alert observed |

This is an important SOC concept because generating an alert for every process creation would create significant noise.

Detection engineering instead focuses on identifying combinations of events and characteristics that provide meaningful security context.

---

# Detection Engineering Perspective

A process creation event alone is not necessarily malicious.

For example:

```text
notepad.exe
    |
    +-- launched by explorer.exe
    +-- located in C:\Windows\System32\
```

would normally be benign.

However, the following combination is more suspicious:

```text
PowerShell
    |
    +-- creates executable
    |
    v
%TEMP%\normalfile2.exe
    |
    +-- executes executable
    |
    v
Process Create
```

A future custom detection could correlate multiple signals instead of alerting on every Event ID 1.

For example:

```text
PowerShell
+
Executable created in a temporary directory
+
Executable subsequently executed
```

could provide a stronger detection signal than any single event.

---

# MITRE ATT&CK

The existing Wazuh alert mapped the activity to:

| Field          | Value                 |
| -------------- | --------------------- |
| Technique      | T1105                 |
| Technique Name | Ingress Tool Transfer |
| Tactic         | Command and Control   |

The simulation itself also demonstrates behavior relevant to executable staging and execution, although the exact ATT&CK mapping should be based on the detection logic rather than automatically assigning a technique to every observed event.

---

# Lessons Learned

### 1. Telemetry is not the same as an alert

Sysmon can generate an event without Wazuh generating a corresponding alert.

```text
Telemetry ≠ Alert
```

---

### 2. Detection rules determine what becomes interesting

Wazuh's rules act as a detection layer between raw telemetry and analyst-facing alerts.

---

### 3. Context matters

A process executing from a normal trusted location is very different from an executable appearing in:

```text
%TEMP%
```

and being launched by:

```text
PowerShell
```

---

### 4. Timeline analysis is important

Initial searches did not always immediately reveal the expected Event ID 1 and Event ID 5 records.

Using an absolute time range around the known execution timestamp made the events easier to locate.

This highlights the importance of timeline-based investigation instead of relying exclusively on keyword searches.

---

### 5. Alert noise must be controlled

A SOC should not necessarily create an alert for every process creation event.

Instead, detection engineering should focus on high-value behavioral combinations.

---

# Evidence

The following evidence was collected during the lab:

* Windows Event Viewer – Sysmon Event ID 11
* Windows Event Viewer – Sysmon Event ID 1
* Windows Event Viewer – Sysmon Event ID 5
* Wazuh Dashboard – Rule 92213
* Wazuh Dashboard – raw Event ID 1 telemetry
* Wazuh Dashboard – raw Event ID 11 telemetry
* PowerShell command history used for simulation

---

# Conclusion

Incident 4 demonstrated the behavior of an executable being staged in a temporary directory and executed through PowerShell.

The most important result was not simply that Wazuh generated an alert, but that the investigation exposed the difference between:

```text
Telemetry
    ↓
Detection Rule
    ↓
Alert
    ↓
Analyst Investigation
```

The executable creation triggered Wazuh Rule 92213, while the subsequent process creation and termination were available as telemetry without producing an equivalent alert.

This provides a practical foundation for the next stage of the lab: **correlation and custom detection engineering**, where multiple low-level events can be combined into a higher-confidence security alert.
