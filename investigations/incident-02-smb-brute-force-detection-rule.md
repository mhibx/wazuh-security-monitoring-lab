# Incident 02 — SMB Brute Force Detection with a Custom Wazuh Rule

## Overview

This investigation builds on the failed SMB authentication scenario from Incident 01.

Instead of treating each failed authentication as an individual alert, this exercise uses a custom Wazuh correlation rule to identify a pattern of repeated authentication failures within a short period of time.

The objective is to demonstrate how individual Windows Security Event ID 4625 events can be correlated into a higher-confidence detection for a potential SMB brute-force attack.

---

## Objectives

- Simulate multiple failed SMB authentication attempts
- Generate Windows Security Event ID 4625
- Observe Wazuh's default authentication failure detection
- Develop a custom Wazuh correlation rule
- Trigger a higher-severity alert after repeated failures
- Validate and document the complete detection workflow

---

## Lab Environment

| Component | Value |
|-----------|-------|
| SIEM | Wazuh 4.x |
| Attacker | Kali Linux |
| Target | Windows 11 |
| Attack Protocol | SMB |
| Windows Event | 4625 |
| Default Wazuh Rule | 60122 |
| Custom Rule | 100100 |

---

## Network Topology

| Host | IP Address |
|------|------------|
| Kali Attacker | 192.168.1.7 |
| Windows 11 | 192.168.1.4 |
| Wazuh Server | 192.168.1.7 |

---

# Attack Simulation

A Bash script was created to generate repeated failed SMB authentication attempts against the Windows endpoint.

~~~bash
./scripts/smb_failed_login.sh
~~~

The script performs five consecutive failed login attempts against the SMB service.

The purpose of the simulation is to generate a sequence of authentication failures that can then be correlated by Wazuh.

---

# Detection Flow

~~~text
Kali Linux
    │
    ▼
Repeated SMB Login Attempts
    │
    ▼
Windows Security Event 4625
    │
    ▼
Wazuh Rule 60122
Logon Failure
    │
    ▼
Custom Rule 100100
Possible SMB Brute Force Attack
~~~

The default rule identifies the individual authentication failures, while the custom rule looks for repeated occurrences within a defined time window.

---

# Custom Detection Rule

The following custom rule correlates five occurrences of Wazuh Rule 60122 within 60 seconds.

~~~xml
<rule id="100100"
      level="10"
      frequency="5"
      timeframe="60">

    <if_matched_sid>60122</if_matched_sid>

    <description>
        Possible SMB Brute Force Attack Detected
    </description>

    <group>windows,authentication,bruteforce,</group>

    <mitre>
        <id>T1110</id>
    </mitre>

</rule>
~~~

### Rule Logic

| Attribute | Value | Purpose |
|-----------|-------|---------|
| Rule ID | 100100 | Custom detection rule |
| Level | 10 | Higher-severity alert |
| Frequency | 5 | Requires five matching events |
| Timeframe | 60 seconds | Events must occur within 60 seconds |
| Parent Rule | 60122 | Matches failed authentication events |
| MITRE ATT&CK | T1110 | Brute Force |

This creates a simple correlation layer above the default authentication failure detection.

---

# Evidence

## Script Execution

The attack simulation script was executed from the Kali Linux attacker machine.

![Script Execution](../screenshots/smbrute-01-multi-scriptexec.png)

---

## Windows Event Viewer

The repeated authentication attempts generated Windows Security Event ID 4625.

| Field | Value |
|-------|-------|
| Event ID | 4625 |
| Authentication Package | NTLM |
| Logon Type | 3 |
| Source IP | 192.168.1.7 |

![Event Viewer](../screenshots/smbrute-02-multi-eventview.png)

These events provided the underlying endpoint telemetry used by Wazuh for detection.

---

## Default Detection

Each failed authentication was initially detected by Wazuh Rule 60122:

~~~text
Rule ID:
60122

Description:
Logon Failure - Unknown user or bad password
~~~

This represents the individual authentication failure events before correlation.

---

## Custom Detection

After the configured threshold was reached, Wazuh triggered the custom correlation rule:

~~~text
Rule ID:
100100

Description:
Possible SMB Brute Force Attack Detected

Level:
10

MITRE ATT&CK:
T1110 - Brute Force
~~~

This demonstrates the difference between an individual event detection and a higher-level detection based on repeated activity.

---

# Detection Timeline

| Time | Event |
|------|-------|
| 10:56:15 | Windows Event ID 4625 |
| 10:56:19 | Windows Event ID 4625 |
| 10:56:22 | Windows Event ID 4625 |
| 10:56:26 | Windows Event ID 4625 |
| 10:56:30 | Custom Rule 100100 Triggered |

![Wazuh Discover](../screenshots/smbrute-03-multi-wazuhdiscover.png)

The timeline shows that the authentication failures occurred within the configured 60-second window. Once the fifth matching event was observed, Wazuh generated the higher-level Rule 100100 alert.

---

# Detection Engineering Notes

One of the main purposes of this exercise was to understand how a SIEM can move from individual events toward behavioral detection.

A single failed authentication does not necessarily indicate an attack. It could be caused by a mistyped password or another benign situation.

However, repeated authentication failures within a short period provide stronger evidence of potentially malicious activity.

The custom rule therefore adds a simple correlation layer:

~~~text
Individual Event
    ↓
Event ID 4625
    ↓
Rule 60122
    ↓
5 matching events within 60 seconds
    ↓
Rule 100100
    ↓
Potential SMB Brute Force Detection
~~~

This approach also provides a foundation for future tuning, such as correlating events by source IP, username, or other attributes.

---

# Lessons Learned

This lab helped me understand how Wazuh can be extended beyond its default detection rules through custom correlation logic.

One important lesson was that `frequency` and `timeframe` are rule attributes used to control event correlation rather than XML elements inside the rule body.

Running `wazuh-analysisd -t` before restarting the Wazuh Manager was also an important part of the workflow. It allowed the custom rule configuration to be validated before applying it to the running environment.

The exercise reinforced several detection engineering concepts:

- Individual authentication failures do not always indicate an attack.
- Repeated events can provide stronger evidence when analyzed as a pattern.
- Correlation rules can turn low-level telemetry into higher-level detections.
- Detection thresholds need to be tuned to balance detection coverage and false positives.
- Validating the rule configuration before deployment helps prevent configuration errors.

---

# Future Improvements

- Correlate authentication failures by source IP
- Correlate repeated failures for the same username
- Tune thresholds to reduce false positives
- Detect password spraying separately from brute-force activity
- Add Active Response to block attacking IP addresses
- Create custom dashboard visualizations
- Correlate authentication failures with additional Windows and SMB events

---

# Skills Demonstrated

- Windows Event Analysis
- SMB Authentication
- Event ID 4625 Investigation
- Wazuh Rule Development
- Detection Engineering
- Event Correlation
- MITRE ATT&CK Mapping
- SIEM Validation
- Security Monitoring

---

# Repository Artifacts

~~~text
investigations/
└── incident-02-smb-brute-force-detection-rule.md

rules/
└── 100100-brute-force.xml

scripts/
└── smb_failed_login.sh

screenshots/
├── smbrute-01-multi-scriptexec.png
├── smbrute-02-multi-eventview.png
└── smbrute-03-multi-wazuhdiscover.png
~~~

---

# Repository Status

**Current Status: Detection Engineering Baseline Completed**

- Multiple SMB authentication failures successfully simulated
- Windows Security Event ID 4625 generated
- Wazuh Rule 60122 validated
- Custom Wazuh Rule 100100 implemented
- Five-event threshold within a 60-second window validated
- Higher-level brute-force detection successfully triggered
- Detection workflow documented

Further improvements will focus on correlation, threshold tuning, false-positive reduction, and distinguishing brute-force activity from other authentication patterns such as password spraying.
