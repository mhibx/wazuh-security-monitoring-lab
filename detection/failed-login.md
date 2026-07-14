# Failed Login Detection

## Overview

This lab demonstrates how Wazuh detects Windows authentication failures by monitoring Windows Security Event Logs.

The objective is to observe how failed authentication attempts are collected, processed, and visualized within the SIEM dashboard.

---

## Objectives

- Simulate failed Windows authentication attempts
- Monitor Windows Security Event Logs
- Detect Event ID 4625
- Analyze authentication-related alerts
- Understand SIEM detection workflow

---

## Detection Scenario

The Windows endpoint was locked and invalid credentials were entered multiple times to generate authentication failure events.

These login attempts generated Windows Security Event **ID 4625**, which were forwarded by the Wazuh Agent to the Wazuh Manager.

---

## Detection Details

| Item | Value |
|------|-------|
| Event ID | 4625 |
| Rule ID | 60122 |
| Severity | 5 |
| Category | authentication_failed |
| Log Source | Windows Security |

---

## Wazuh Detection

The following activities were successfully detected:

- Failed logon attempts
- Invalid credentials
- Windows Security events
- Authentication failure alerts

---

## Screenshots

> Add screenshots in `/screenshots`

- Failed Login Alert
- Event Details
- Dashboard Timeline

---

## Skills Demonstrated

- SIEM Monitoring
- Windows Event Analysis
- Authentication Monitoring
- Log Analysis
- Alert Investigation

---

## References

- Microsoft Event ID 4625
- Wazuh Documentation
