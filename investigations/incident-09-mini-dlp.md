# Mini DLP Detection & Investigation Lab

A small, controlled Data Loss Prevention (DLP) lab demonstrating how sensitive-data classification and destination-based policy evaluation can be converted into structured telemetry and detected through Wazuh.

## Objective

Build a lightweight DLP workflow that can:

1. Identify sensitive data using simple content patterns.
2. Evaluate whether the destination is restricted.
3. Produce a structured JSON policy event.
4. Ingest the event through the Wazuh Windows agent.
5. Detect policy violations with a custom Wazuh rule.
6. Validate the detection with positive and negative tests.

This is a **mini lab**, not a replacement for an enterprise DLP platform.

## Lab Structure

```text
Windows 11 endpoint (X390)
│
├── C:\SOC-Lab\DLP\Sensitive\
│   └── customer_records.csv
│
├── C:\SOC-Lab\DLP\Internal\
│
├── C:\SOC-Lab\DLP\USB\
│
├── C:\SOC-Lab\DLP\Public\
│   └── product_catalog.csv
│
├── C:\SOC-Lab\DLP\Logs\
│   └── dlp-events.json
│
└── C:\SOC-Lab\DLP\Tools\
    └── dlp_scanner.py
          │
          ▼
     Wazuh Agent
          │
          ▼
     Wazuh Manager
          │
          ▼
     JSON Decoder
          │
          ▼
     Custom Rule 100301
          │
          ▼
       Level 10 Alert
```

## Test Data

### Sensitive dataset

`customer_records.csv` contains dummy customer records with:

- customer IDs
- names
- email addresses
- phone numbers

The scanner detected 5 matches for each of the email, phone, and customer ID patterns in the tested file.

### Non-sensitive baseline

`product_catalog.csv` contains dummy product catalogue data and was classified as `NON-SENSITIVE`.

## Policy Logic

The lab uses a simple policy model:

```text
SENSITIVE + restricted destination = VIOLATION
SENSITIVE + allowed destination    = ALLOW
NON-SENSITIVE + restricted target  = ALLOW
```

The simulated USB directory is treated as a restricted destination.

## Structured DLP Event

The scanner writes a JSON event to:

```text
C:\SOC-Lab\DLP\Logs\dlp-events.json
```

Example event shape:

```json
{
  "event_type": "dlp_policy",
  "file": "customer_records.csv",
  "source": "C:\\SOC-Lab\\DLP\\Sensitive\\customer_records.csv",
  "destination": "C:\\SOC-Lab\\DLP\\USB\\customer_records.csv",
  "classification": "SENSITIVE",
  "restricted_target": true,
  "decision": "VIOLATION",
  "findings": {
    "email": 5,
    "phone": 5,
    "customer_id": 5
  }
}
```

## Wazuh Integration

The Windows agent monitors the JSON log with a JSON `localfile` configuration:

```xml
<localfile>
    <location>C:\SOC-Lab\DLP\Logs\dlp-events.json</location>
    <log_format>json</log_format>
</localfile>
```

The event was confirmed in Wazuh Manager archives with the JSON decoder and the expected structured fields.

## Detection Rule

Custom Wazuh rule:

```xml
<rule id="100301" level="10">
  <decoded_as>json</decoded_as>
  <field name="event_type">^dlp_policy$</field>
  <field name="classification">^SENSITIVE$</field>
  <field name="restricted_target">^true$</field>
  <field name="decision">^VIOLATION$</field>
  <description>DLP policy violation: sensitive data sent to restricted destination</description>
  <group>dlp,data_loss_prevention,policy_violation,</group>
</rule>
```

The rule was validated before deployment:

- `wazuh-analysisd -t` returned `OK`.
- `wazuh-logtest` successfully decoded the JSON event.
- Phase 3 matched Rule `100301` at Level `10`.
- Wazuh Manager restarted successfully after the rule was loaded.

## Test Results

| Test | Classification | Destination | Expected | Result |
|---|---|---|---|---|
| Positive | SENSITIVE | USB | VIOLATION | PASS |
| Negative 1 | SENSITIVE | Internal | ALLOW | PASS |
| Negative 2 | NON-SENSITIVE | USB | ALLOW | PASS |

### Positive Test

`customer_records.csv` was evaluated against the simulated USB destination:

```text
Classification   : SENSITIVE
Restricted target: YES
Policy decision  : VIOLATION
```

The event generated a Wazuh Level 10 alert using Rule `100301`.

### Negative Test 1

The same sensitive dataset was evaluated against the Internal destination:

```text
Classification   : SENSITIVE
Restricted target: NO
Policy decision  : ALLOW
```

This demonstrates that sensitive data alone does not automatically trigger the violation policy.

### Negative Test 2

The non-sensitive product catalogue was evaluated against the simulated USB destination:

```text
Classification   : NON-SENSITIVE
Restricted target: YES
Policy decision  : ALLOW
```

This demonstrates that a restricted destination alone does not automatically trigger the violation policy.

## Detection Validation

The final alert was confirmed in:

```text
/var/ossec/logs/alerts/alerts.json
```

The alert contained:

- Rule ID `100301`
- Level `10`
- agent `X390`
- source and destination paths
- `classification: SENSITIVE`
- `restricted_target: true`
- `decision: VIOLATION`
- finding counts
- JSON decoder metadata

A follow-up search for Rule `100301` after the negative tests showed only the earlier positive violation event, confirming that the tested negative scenarios did not generate the DLP alert.

## SOC / Detection Engineering Takeaways

This lab demonstrates several practical SOC concepts:

- **Data classification** before deciding whether an event is suspicious.
- **Policy-aware detection** rather than alerting on a single keyword or path.
- **Structured telemetry** that can be consumed by a SIEM.
- **Custom Wazuh rule development** using decoded JSON fields.
- **Positive testing** to prove the intended alert fires.
- **Negative testing** to reduce overly broad detection logic.
- **Evidence-based validation** through both `wazuh-logtest` and `alerts.json`.

## Limitations

This implementation is intentionally small and controlled. It does not provide:

- kernel-level or filesystem-wide data movement monitoring
- native removable-media control
- network DLP inspection
- cloud/SaaS DLP
- enterprise content classification
- automatic blocking or quarantine
- OCR or advanced document inspection

The USB directory is a **simulated restricted destination** for lab purposes.

## Evidence

### Rule creation

![Rule 100301 added](screenshots/01-rule-100301-added.png)

### Wazuh logtest

![Wazuh logtest matched Rule 100301](screenshots/02-wazuh-logtest-rule-match.png)

### Wazuh Manager restart

![Wazuh Manager restarted successfully](screenshots/03-wazuh-manager-restarted.png)

### Positive DLP policy test

![Sensitive data sent to simulated USB](screenshots/04-positive-test-sensitive-to-usb.png)

### Wazuh Level 10 alert

![Wazuh Rule 100301 alert](screenshots/05-wazuh-alert-rule-100301.png)

### Negative test: sensitive to Internal

![Sensitive data to allowed Internal destination](screenshots/06-negative-sensitive-to-internal.png)

### Negative test: non-sensitive to USB

![Non-sensitive data to restricted USB destination](screenshots/07-negative-nonsensitive-to-usb.png)

### Negative alert verification

![Negative test verification in Wazuh alerts](screenshots/08-negative-alert-check.png)
