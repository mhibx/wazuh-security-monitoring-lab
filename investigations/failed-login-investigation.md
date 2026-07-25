# Failed Login Investigation

## Investigation Summary

This investigation analyzes authentication failure events generated from invalid Windows login attempts.

The goal is to understand how Wazuh collects, correlates, and presents authentication-related security events.

---

## Evidence

| Field | Value |
|------|-------|
| Event ID | 4625 |
| Event Type | Failed Logon |
| Endpoint | WIN11 |
| Rule ID | 60122 |
| Severity | 5 |

---

## Timeline

1. Windows endpoint locked.
2. Invalid credentials entered.
3. Windows generated Event ID 4625.
4. Wazuh Agent forwarded the log.
5. Wazuh Manager triggered Rule 60122.
6. Alert appeared in the Threat Hunting dashboard.

![Endpoint Dashboard](../screenshots/failed-01-endpointdashboard.png)

---

## Findings

The investigation confirmed:

- Invalid login credentials
- Authentication failure
- Successful log forwarding
- Correct rule triggering
- Real-time dashboard visualization

![Event Analysis](../screenshots/failed-02-eventanalysis.png)

---

## Security Relevance

Authentication failures may indicate:

- User mistakes
- Password spraying
- Credential stuffing
- Initial brute-force attempts

Monitoring Event ID 4625 provides early visibility into suspicious authentication activity.

---

## Lessons Learned

- Windows Security logs provide valuable authentication telemetry.
- Wazuh successfully centralizes authentication events.
- Event correlation improves analyst visibility.
