# Custom Wazuh Rules

Custom Wazuh rules are used in this lab to extend the default detection capabilities of Wazuh and create detection logic specific to the simulated security scenarios.

The main custom detection implemented in this lab focuses on repeated Windows authentication failures that may indicate a brute-force attack.

The custom rule is stored in:

```text
rules/100100-brute-force.xml
```

## Objectives

- Understand how Wazuh detection rules work
- Extend default Wazuh detection logic
- Correlate multiple authentication failure events
- Detect repeated login failures within a defined time window
- Create a higher-level security alert
- Map the detection to MITRE ATT&CK
- Validate the rule before applying it to the Wazuh Manager

## Why Custom Rules?

Wazuh already provides many built-in detection rules.

For example, Windows authentication failures can trigger the default rule:

```text
Rule ID: 60122
Description: Logon Failure - Unknown user or bad password
```

A single failed login attempt, however, does not necessarily indicate an attack.

A user may simply enter an incorrect password.

Repeated authentication failures occurring within a short period provide stronger evidence of possible brute-force activity.

The custom rule therefore builds on the existing detection instead of replacing it.

## Detection Logic

The detection flow used in this lab is:

```text
Windows Security Event 4625
          │
          ▼
Wazuh Default Rule 60122
          │
          ▼
Repeated Authentication Failures
          │
          ▼
Custom Rule 100100
          │
          ▼
Possible SMB Brute Force Alert
```

The custom rule does not directly parse the Windows event itself.

Instead, it uses the existing Wazuh detection:

```text
60122
```

as the basis for correlation.

## Default Rule

The default authentication failure detection observed during the lab was:

```text
Rule ID:
60122

Description:
Logon Failure - Unknown user or bad password
```

This rule provides the individual authentication failure events used by the custom correlation rule.

## Custom Rule

The custom rule is:

```xml
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
```

## Rule Components

### Rule ID

```text
100100
```

The rule uses a custom rule ID in the local custom-rule range.

This makes it easier to distinguish organization-specific detection logic from Wazuh's built-in rules.

### Alert Level

```text
level="10"
```

The rule generates a level 10 alert when the defined correlation condition is satisfied.

The alert level represents the severity assigned by the detection logic and should still be evaluated together with the actual investigation context.

### Frequency

```text
frequency="5"
```

The rule requires five matching events before the custom detection is triggered.

In this lab, the matching event is Wazuh Rule `60122`.

Therefore:

```text
5 × Rule 60122
        ↓
Rule 100100
```

### Timeframe

```text
timeframe="60"
```

The five matching events must occur within a 60-second window.

This prevents widely separated authentication failures from being treated as one brute-force sequence.

The detection logic can therefore be summarized as:

```text
5 authentication failures
        +
within 60 seconds
        ↓
Possible Brute Force Detection
```

### if_matched_sid

```xml
<if_matched_sid>60122</if_matched_sid>
```

This tells Wazuh to correlate events that previously matched Rule `60122`.

This is an important part of the detection because the custom rule is building on an existing Wazuh detection rather than independently identifying every authentication failure.

### Description

```text
Possible SMB Brute Force Attack Detected
```

The description communicates the purpose of the alert to the analyst.

The word `Possible` is intentional because repeated authentication failures are suspicious but do not automatically prove that a brute-force attack occurred.

### Group

```text
windows,authentication,bruteforce,
```

The group provides additional classification for the alert.

This makes the detection easier to identify and organize alongside other Windows authentication and brute-force detections.

### MITRE ATT&CK

```xml
<mitre>
    <id>T1110</id>
</mitre>
```

The detection is mapped to:

```text
T1110 - Brute Force
```

This connects the detection to the MITRE ATT&CK framework.

## Validation

Before restarting the Wazuh Manager, the custom rule configuration should be validated.

The validation performed during this lab used:

```bash
wazuh-analysisd -t
```

The validation step is important because an invalid rule configuration can prevent the Wazuh Manager from starting correctly.

The general workflow is:

```text
Edit Custom Rule
       │
       ▼
Validate Configuration
       │
       ├── Error
       │    └── Fix Rule
       │
       └── Valid
            │
            ▼
      Restart Wazuh Manager
```

This validation step was particularly important when working with the `frequency` and `timeframe` attributes.

These are rule attributes and should be defined directly on the `<rule>` element.

## Attack Simulation

The rule was tested using repeated failed SMB authentication attempts from the Kali Linux system against the Windows endpoint.

The simulation script is stored in:

```text
scripts/smb_failed_login.sh
```

The script performs multiple failed authentication attempts to generate Windows Security Event ID `4625`.

The resulting detection sequence is:

```text
Kali Linux
    │
    ▼
Repeated SMB Login Attempts
    │
    ▼
Windows Event ID 4625
    │
    ▼
Wazuh Rule 60122
    │
    ▼
5 Matching Events
    │
    ▼
Custom Rule 100100
    │
    ▼
Level 10 Alert
```

## Observed Timeline

During the investigation, the authentication failures occurred within the configured time window.

Example timeline:

| Time | Event |
|---|---|
| 10:56:15 | Windows Event ID 4625 |
| 10:56:19 | Windows Event ID 4625 |
| 10:56:22 | Windows Event ID 4625 |
| 10:56:26 | Windows Event ID 4625 |
| 10:56:30 | Custom Rule 100100 triggered |

The individual authentication failures were detected by Rule `60122`.

After the required number of matching events occurred within the configured timeframe, Rule `100100` generated the higher-level brute-force detection.

## Detection Result

The resulting custom alert contained:

```text
Rule ID:
100100

Level:
10

Description:
Possible SMB Brute Force Attack Detected

MITRE ATT&CK:
T1110 - Brute Force
```

This demonstrates the difference between an individual authentication failure and a correlated security detection.

```text
Single Failed Login
        ↓
Rule 60122
        ↓
Authentication Failure

Multiple Failures
        ↓
Rule 60122 × 5
        ↓
Rule 100100
        ↓
Possible Brute Force Attack
```

## Investigation Usage

The custom rule is used together with the investigation documented in:

```text
investigations/incident-02-smb-brute-force-detection-rule.md
```

The investigation provides the supporting evidence for:

- Windows Event ID 4625
- SMB authentication failures
- Default Wazuh Rule 60122
- Custom Wazuh Rule 100100
- Detection timeline
- MITRE ATT&CK mapping

The custom rule therefore represents the detection-engineering component of the incident, while the investigation documents the analyst workflow and evidence.

## Screenshots

The following screenshots document the custom-rule implementation and validation.

### Custom Rule Configuration

![Custom Rule](../screenshots/rules-01-custom-rule.png)

### Rule Validation

![Rule Validation](../screenshots/rules-02-validation.png)

### Custom Alert

![Custom Alert](../screenshots/rules-03-custom-alert.png)

If the exact screenshots are not yet available, these filenames can be used as placeholders and replaced after the evidence is collected.

## False Positive Considerations

Repeated authentication failures do not always indicate malicious activity.

Possible legitimate causes include:

- User repeatedly entering an incorrect password
- Expired credentials
- Incorrectly configured applications
- Services using outdated credentials
- Automated systems attempting authentication with invalid credentials

For this reason, the alert should be treated as an investigation starting point rather than automatic proof of compromise.

Additional context should be considered, including:

```text
Source IP
    ↓
Username
    ↓
Number of Failures
    ↓
Time Window
    ↓
Logon Type
    ↓
Successful Authentication
    ↓
Other Endpoint Activity
```

## Current Limitations

The current rule focuses on the number of matching authentication failure events within a time window.

It does not yet correlate the events specifically by:

- Source IP address
- Username
- Destination account
- SMB service
- Authentication type

Because of this, the current rule should be considered a basic correlation rule suitable for demonstrating detection engineering in the lab.

## Future Improvements

Future versions could improve the detection by correlating additional context.

Potential improvements include:

- Correlate failures by source IP
- Correlate failures against the same username
- Detect password spraying separately
- Detect successful authentication after repeated failures
- Add source-IP-based thresholds
- Reduce false positives
- Add Active Response for confirmed malicious sources
- Create dedicated Wazuh dashboard visualizations
- Build additional correlation rules for Windows authentication attacks

## Lessons Learned

This lab demonstrated that custom Wazuh rules can transform low-level telemetry into higher-level security detections.

The most important concept is:

```text
Telemetry
    ↓
Existing Detection
    ↓
Correlation
    ↓
Higher-Confidence Alert
    ↓
Analyst Investigation
```

A single failed login is usually weak evidence.

Multiple failures occurring within a short period provide stronger evidence and can justify generating a dedicated security alert.

This approach demonstrates the basic principle of detection engineering: create detection logic around meaningful behavioral patterns rather than relying only on individual events.

## Repository Reference

```text
docs/
└── custom-rules.md

rules/
├── 100100-brute-force.xml
└── local_rules.xml

scripts/
└── smb_failed_login.sh

investigations/
└── incident-02-smb-brute-force-detection-rule.md
```
