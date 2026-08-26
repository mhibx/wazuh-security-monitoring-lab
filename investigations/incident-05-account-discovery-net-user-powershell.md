# Incident 05 — Account Discovery via `net user` from PowerShell

## Overview

This investigation documents the detection of Windows account discovery activity performed through the `net user` command, where the process was spawned by PowerShell.

The objective was to create a custom Wazuh detection rule that identifies the combination of:

- `net.exe`
- `net user`
- PowerShell as the parent process

Rather than detecting `net user` alone, the detection uses process ancestry from Sysmon telemetry to identify the relationship between the child process and its PowerShell parent.

This investigation demonstrates a layered detection approach:

```text
Sysmon Process Creation
        ↓
Wazuh built-in detection
        ↓
Custom detection rule
        ↓
MITRE ATT&CK classification
        ↓
Level 7 alert
```

---

## Environment

| Component | Value |
|---|---|
| Endpoint | `X390` |
| Endpoint IP | `192.168.1.4` |
| Operating System | Windows |
| Telemetry | Sysmon |
| Sysmon Event | Event ID 1 — Process Create |
| SIEM | Wazuh |
| Wazuh Agent ID | `001` |
| Wazuh Manager | `mhibx` |

---

## Detection Objective

The detection was designed to identify account discovery performed with:

```powershell
net user
```

when the command is executed from PowerShell.

The expected process relationship is:

```text
powershell.exe
    └── net.exe user
```

This is more specific than simply detecting `net.exe` or `net user`, because the parent-child process relationship provides additional behavioral context.

---

## Attack Simulation

The simulated activity was:

```powershell
net user
```

The resulting Sysmon telemetry showed:

```text
Image:
C:\Windows\System32\net.exe

CommandLine:
"C:\WINDOWS\system32\net.exe" user

ParentImage:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

ParentCommandLine:
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
```

The important process relationship was:

```text
powershell.exe
    │
    └── net.exe
        CommandLine: net.exe user
```

---

## Initial Detection

The event was initially detected by the Wazuh built-in rule:

```text
Rule ID: 92033
Level: 3
Description: Discovery activity spawned via powershell execution
```

The rule classified the activity as:

```text
T1087     - Account Discovery
T1059.001 - Command and Scripting Interpreter: PowerShell
```

However, the built-in rule was relatively generic.

The objective was therefore to create a more specific local detection for:

```text
net user
    +
PowerShell parent process
```

---

## Custom Detection Rule

A custom Wazuh rule was created in:

```text
/var/ossec/etc/rules/local_rules.xml
```

The final rule was:

```xml
<rule id="100101" level="7">
  <if_sid>92033</if_sid>
  <field name="win.eventdata.parentImage" type="pcre2">(?i)\\powershell(?:\.exe)?$</field>
  <description>Account discovery using net user from PowerShell</description>
  <mitre>
    <id>T1087.001</id>
    <id>T1059.001</id>
  </mitre>
  <group>account_discovery,windows,sysmon,</group>
</rule>
```

### Detection Logic

The rule uses:

```xml
<if_sid>92033</if_sid>
```

to build on the existing Wazuh detection.

It then evaluates:

```text
win.eventdata.parentImage
```

to confirm that the process was spawned by PowerShell.

The rule therefore acts as a more specific detection layer on top of the existing rule.

---

## Why `parentImage` Was Used

The Sysmon event contains process ancestry information.

Relevant fields include:

```text
parentProcessGuid
parentProcessId
parentImage
parentCommandLine
parentUser
```

For the successful event:

```text
parentProcessId:
13836

parentImage:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

parentCommandLine:
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
```

The child process was:

```text
image:
C:\Windows\System32\net.exe

commandLine:
"C:\WINDOWS\system32\net.exe" user
```

This confirms the process relationship:

```text
powershell.exe → net.exe user
```

---

## Troubleshooting

The initial version of the rule did not generate the expected Level 7 alert.

The event continued to trigger:

```text
Rule ID: 92033
Level: 3
```

Several possibilities were considered:

1. Incorrect parent rule ID
2. Incorrect Wazuh field path
3. `local_rules.xml` not being loaded
4. Regex mismatch
5. Rule ordering or rule evaluation issue

The investigation confirmed that:

- `local_rules.xml` was being loaded
- The correct parent rule was `92033`
- The correct field path was `win.eventdata.parentImage`
- The custom rule could successfully match the event

The final working regex field was placed on a single line:

```xml
<field name="win.eventdata.parentImage" type="pcre2">(?i)\\powershell(?:\.exe)?$</field>
```

This resolved the matching issue observed during testing.

---

## Successful Detection

The successful alert generated:

```text
Rule ID:
100101

Level:
7

Description:
Account discovery using net user from PowerShell
```

The alert also contained the MITRE ATT&CK mapping:

```text
T1087.001  - Account Discovery: Local Account
T1059.001  - Command and Scripting Interpreter: PowerShell
```

The final alert therefore demonstrated that the custom rule successfully matched the event.

---

## Evidence

### Process Creation

```text
Image:
C:\Windows\System32\net.exe

CommandLine:
"C:\WINDOWS\system32\net.exe" user

ParentImage:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

ParentProcessId:
13836

ProcessId:
19708
```

### Wazuh Detection

```text
Rule ID: 100101
Level: 7
Description: Account discovery using net user from PowerShell
```

### MITRE ATT&CK

```text
T1087.001 — Account Discovery: Local Account
T1059.001 — Command and Scripting Interpreter: PowerShell
```

---

## Detection Chain

The final detection chain is:

```text
Windows
  │
  └── Sysmon Event ID 1
        │
        ├── Image: net.exe
        ├── CommandLine: net.exe user
        └── ParentImage: powershell.exe
                │
                ▼
        Wazuh Rule 92033
                │
                ▼
        Custom Rule 100101
                │
                ├── Level 7
                ├── T1087.001
                └── T1059.001
```

This demonstrates how a generic detection can be enriched with additional process-context information.

---

## Investigation Notes

The activity was generated intentionally as part of the security monitoring lab.

The command:

```powershell
net user
```

is a legitimate Windows administrative command and is not inherently malicious.

Therefore, this detection should not automatically be interpreted as confirmed malicious activity.

The detection instead identifies a behavior that can be relevant during post-compromise reconnaissance or account discovery.

Additional context should be considered during a real investigation, including:

- User executing the command
- Parent process
- Parent command line
- Process ancestry
- Host involved
- Interactive vs automated execution
- Frequency of execution
- Other discovery commands executed around the same time
- Network activity
- Authentication activity
- PowerShell command history or additional telemetry

---

## Detection Engineering Lessons

### 1. Process ancestry provides valuable context

Detecting:

```text
net.exe
```

alone is relatively broad.

Adding:

```text
ParentImage = powershell.exe
```

provides additional behavioral context.

---

### 2. Built-in rules can be used as detection primitives

Instead of rebuilding the entire detection from Sysmon Event ID 1, the custom rule uses:

```xml
<if_sid>92033</if_sid>
```

This allows the custom rule to build on an existing Wazuh detection.

The resulting architecture is:

```text
Telemetry
    ↓
Base Detection
    ↓
Specific Detection
```

This can make custom rules easier to maintain.

---

### 3. Raw event evidence should drive rule development

The rule was developed from the actual Sysmon event structure rather than assuming the field names.

The relevant field was verified from the event:

```text
win.eventdata.parentImage
```

This helped avoid creating a rule based on an incorrect field path.

---

### 4. Alert severity can be increased through contextual enrichment

The original detection generated:

```text
92033 → Level 3
```

The custom detection generated:

```text
100101 → Level 7
```

The higher severity represents the additional specificity provided by the custom detection.

It does not by itself mean the activity is malicious.

---

## Validation Status

| Test | Result |
|---|---|
| Sysmon Event ID 1 received | PASS |
| `net.exe` telemetry observed | PASS |
| `net user` command observed | PASS |
| PowerShell parent observed | PASS |
| Built-in Rule 92033 triggered | PASS |
| Custom Rule 100101 loaded | PASS |
| Parent process condition matched | PASS |
| Level 7 alert generated | PASS |
| MITRE mapping generated | PASS |

---

## Conclusion

The investigation successfully implemented and validated a custom Wazuh detection for:

```text
net user
```

executed through:

```text
PowerShell
```

The final detection uses process ancestry to provide additional context and builds upon Wazuh's existing detection rule.

The successful alert confirms the following detection chain:

```text
Sysmon Event ID 1
        ↓
Wazuh Rule 92033
        ↓
Custom Rule 100101
        ↓
Level 7
        ↓
T1087.001 + T1059.001
```

This investigation demonstrates a practical detection engineering workflow:

```text
Observe telemetry
      ↓
Identify behavioral pattern
      ↓
Validate field structure
      ↓
Reuse existing detection
      ↓
Add contextual condition
      ↓
Test and troubleshoot
      ↓
Validate final alert
      ↓
Document investigation
```

---

## References

- MITRE ATT&CK — T1087.001: Account Discovery: Local Account
- MITRE ATT&CK — T1059.001: Command and Scripting Interpreter: PowerShell
- Sysmon Event ID 1 — Process Create
- Wazuh custom rules — `local_rules.xml`
