# Suricata Rules

## Objective

Create a simple custom Suricata rule to verify that the IDS can detect controlled network traffic.

The rule is intentionally simple and is used to validate the detection pipeline before integrating Suricata alerts with Wazuh.

---

## Detection Workflow

The detection workflow used in this lab is:

```text
Generate controlled network traffic
              │
              ▼
       Suricata inspects traffic
              │
              ▼
       Custom rule matches
              │
              ▼
        Alert is generated
              │
              ▼
       Alert is analyzed
              │
              ▼
    Prepare for Wazuh integration
```

---

## Rule Structure

A Suricata rule generally consists of:

```text
action protocol source_ip source_port direction destination_ip destination_port (options)
```

For example:

```text
alert icmp any any -> any any (msg:"LAB ICMP Traffic Detected"; sid:1000001; rev:1;)
```

This rule generates an alert whenever Suricata detects ICMP traffic matching the defined conditions.

---

## Rule Components

| Component | Value | Purpose |
|-----------|-------|---------|
| Action | `alert` | Generate an alert when the rule matches |
| Protocol | `icmp` | Inspect ICMP traffic |
| Source | `any any` | Match any source IP and port |
| Direction | `->` | Define the traffic direction |
| Destination | `any any` | Match any destination IP and port |
| Message | `LAB ICMP Traffic Detected` | Description shown in the alert |
| SID | `1000001` | Unique rule identifier |
| Revision | `1` | Rule revision number |

---

## Custom Rule

The custom rule used in this lab is:

```text
alert icmp any any -> any any (msg:"LAB ICMP Traffic Detected"; sid:1000001; rev:1;)
```

The rule is stored in the Suricata rules directory and loaded by the active Suricata configuration.

---

## Testing

The rule is tested using controlled ICMP traffic generated from the lab environment.

Example:

```bash
ping <target-ip>
```

The purpose of the test is not to simulate a real attack, but to verify that:

1. Network traffic reaches the monitored interface.
2. Suricata inspects the traffic.
3. The custom rule matches the traffic.
4. Suricata generates an alert.
5. The alert can be reviewed from the Suricata event logs.

---

## Alert Verification

Suricata alerts can be reviewed from:

```text
/var/log/suricata/fast.log
```

Structured events are also available in:

```text
/var/log/suricata/eve.json
```

Example command:

```bash
sudo tail -f /var/log/suricata/fast.log
```

Or:

```bash
sudo tail -f /var/log/suricata/eve.json
```

When the rule matches, the generated event should contain the custom message:

```text
LAB ICMP Traffic Detected
```

---

## Result

The custom rule provides a controlled way to validate the Suricata detection pipeline.

This establishes the foundation for the next stage of the lab, where Suricata alerts can be forwarded to Wazuh for centralized monitoring and investigation.

---

## Security Relevance

This exercise demonstrates the basic workflow of network-based detection engineering:

```text
Traffic
   ↓
Telemetry
   ↓
Detection Rule
   ↓
Alert
   ↓
Investigation
```

The same principle can later be extended to more realistic network activity and integrated with Wazuh for centralized security monitoring.

---

## Notes

The rule is intentionally broad and is only intended for controlled lab testing.

It should not be treated as a production detection rule without additional tuning, filtering, and validation.
