# Wazuh Dashboard — Indexing Failure Caused by Disk Flood-Stage Watermark

## Overview

This case documents a troubleshooting investigation where recent Windows
telemetry and Wazuh alerts were not visible in the Wazuh Dashboard.

The investigation initially suggested a possible telemetry or detection
pipeline failure. Endpoint telemetry was then validated layer by layer
until the root cause was identified as disk pressure on the Wazuh server.

The Wazuh Indexer had reached its disk flood-stage watermark and applied
a `read_only_allow_delete` block to affected indices.

After disk space was recovered, Wazuh resumed indexing new events and
the expected security alert became visible again.

---

## Environment

| Component | Role |
|---|---|
| X390 | Windows 11 endpoint |
| Sysmon | Windows endpoint telemetry |
| Wazuh Agent | Endpoint telemetry collection |
| mhibx | Wazuh server / manager |
| Wazuh Indexer | Event indexing and storage |
| Wazuh Dashboard | Security monitoring interface |

### Telemetry Path

    Windows X390
        │
        │ Sysmon telemetry
        ▼
    Wazuh Agent
        │
        │ TCP/1514
        ▼
    Wazuh Manager
        │
        ▼
    Wazuh Indexer
        │
        ▼
    Wazuh Dashboard

---

## Initial Symptom

The Wazuh Dashboard did not display recent activity from the Windows
endpoint.

A search for recent Sysmon process creation events returned:

    No Results

The initial question was whether the problem was caused by:

- Sysmon not generating events
- Wazuh Agent not collecting events
- Agent-to-manager connectivity
- Wazuh detection rules
- Wazuh Manager ingestion
- Wazuh Indexer
- Dashboard/indexing

Rather than assuming the detection rule was broken, the telemetry
pipeline was investigated layer by layer.

---

# Investigation

## 1. Verify Sysmon Telemetry

The Windows endpoint was checked directly using PowerShell.

    Get-WinEvent -FilterHashtable @{
        LogName='Microsoft-Windows-Sysmon/Operational'
        Id=1
        StartTime=(Get-Date).AddMinutes(-5)
    } | Select-Object TimeCreated, Id, Message | Select-Object -First 10

Recent Sysmon Event ID 1 records were present.

Example:

    8/28/2026 6:48:13 PM    1    Process Create:...
    8/28/2026 6:48:10 PM    1    Process Create:...
    8/28/2026 6:48:08 PM    1    Process Create:...

### Finding

Sysmon was generating telemetry successfully.

Therefore, the problem was not located at the endpoint telemetry
generation layer.

---

## 2. Verify Wazuh Agent Service

The Wazuh Agent service was checked on the Windows endpoint.

    Get-Service WazuhSvc

Result:

    Status    Name
    ------    ----
    Running   WazuhSvc

The agent service was running.

---

## 3. Verify Network Connectivity

Connectivity from the Windows endpoint to the Wazuh Manager was tested.

    Test-NetConnection 192.168.1.7 -Port 1514

Result:

    ComputerName     : 192.168.1.7
    RemoteAddress    : 192.168.1.7
    RemotePort       : 1514
    InterfaceAlias   : Wi-Fi
    SourceAddress    : 192.168.1.4
    TcpTestSucceeded : True

The Wazuh Agent log also showed successful connections:

    Connected to the server ([192.168.1.7]:1514/tcp).
    Agent is now online. Process unlocked, continuing...

### Finding

The endpoint could communicate with the Wazuh Manager and the agent
was able to reconnect successfully.

---

## 4. Verify Wazuh Agent Activity

The Wazuh Agent log was inspected:

    Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 100

The log showed both temporary connectivity failures and subsequent
successful reconnection.

Example:

    Trying to connect to server ([192.168.1.7]:1514/tcp).
    Connected to the server ([192.168.1.7]:1514/tcp).
    Agent is now online. Process unlocked, continuing...

### Finding

The agent experienced connectivity interruptions, but it was able to
reconnect and return to an online state.

This did not fully explain why recent events were not appearing in the
Dashboard.

---

## 5. Check Wazuh Manager Alert Output

The Wazuh Manager was checked directly rather than relying only on the
Dashboard.

    sudo tail -20 /var/ossec/logs/alerts/alerts.json | \
    jq -c 'select(.rule.id=="100101")'

A new alert was present:

    rule.id: 100101
    description: Account discovery using net user from PowerShell
    level: 7

The event contained:

    Host:
    X390

    User:
    X390\tempo

    Process:
    C:\Windows\System32\net.exe

    CommandLine:
    "C:\WINDOWS\system32\net.exe" user

    ParentImage:
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

MITRE ATT&CK mappings:

    T1087.001 — Account Discovery: Local Account
    T1059.001 — Command and Scripting Interpreter: PowerShell

### Finding

The Wazuh Manager was successfully processing the event and the
custom detection rule was firing.

Therefore, the detection rule itself was not the root cause.

---

## 6. Check Wazuh Archive Telemetry

Wazuh archive data was also inspected:

    sudo tail -50 /var/ossec/logs/archives/archives.json | \
    jq -c 'select(.data.win.system.providerName=="Microsoft-Windows-Sysmon")'

Sysmon telemetry was present in the archive.

For example, a Sysmon Event ID 2 was observed:

    providerName:
    Microsoft-Windows-Sysmon

    eventID:
    2

    RuleName:
    T1099

    Image:
    C:\Users\tempo\AppData\Local\Discord\app-1.0.9253\Discord.exe

### Finding

The Wazuh Manager was receiving and processing Sysmon telemetry.

The investigation therefore moved further downstream toward the
Indexer and storage layer.

---

## 7. Check Disk Utilization

The Wazuh server filesystem was inspected:

    df -h

Initial result:

    Filesystem      Size  Used Avail Use%
    /dev/sda2       218G  193G   15G  94%

The root filesystem was at approximately 94% utilization.

Additional investigation showed that `/var` consumed significant space:

    59G    /var

The Suricata logs were a major contributor:

    7.5G    /var/log/suricata

The largest Suricata files included:

    6.1G    /var/log/suricata/eve.json
    1.2G    /var/log/suricata/fast.log

This indicated significant disk pressure on the Wazuh server.

---

## 8. Identify the Indexer Error

The Wazuh Indexer reported:

    indexer-connector: WARNING: Indexer request failed

    type:
    cluster_block_exception

    reason:
    index [wazuh-states-inventory-interfaces-mhibx]
    blocked by:
    [TOO_MANY_REQUESTS/12/disk usage exceeded flood-stage watermark,
    index has read-only-allow-delete block]

This provided the root-cause evidence.

The Indexer had detected that disk usage exceeded its flood-stage
watermark and protected the cluster by applying a read-only block to
the affected index.

---

# Root Cause

The Wazuh server filesystem experienced high disk utilization.

At approximately:

    94% disk utilization

the Wazuh Indexer reached its configured flood-stage watermark.

The Indexer consequently applied:

    read_only_allow_delete

to affected indices.

This prevented normal indexing operations and resulted in missing
recent data from the Dashboard.

The issue was therefore not caused by:

- Sysmon
- the Windows endpoint
- the Wazuh detection rule
- the Wazuh Agent configuration

The failure occurred at the storage/indexing layer.

---

# Remediation

Disk space was recovered by removing unnecessary files from the user's
desktop Trash.

The following command was used:

    rm -rf ~/.local/share/Trash/*

After cleanup:

    df -h /

showed:

    Filesystem      Size  Used Avail Use%
    /dev/sda2       218G  165G   42G  80%

Disk utilization decreased from:

    94% → 80%

This provided sufficient free space for the Indexer to resume normal
operation.

---

# Validation

After disk space was recovered, a new `net user` test was performed.

The Wazuh Manager successfully generated rule `100101`:

    rule:
        id: 100101
        level: 7
        description:
            Account discovery using net user from PowerShell

The alert was written to:

    /var/ossec/logs/alerts/alerts.json

The event timestamp demonstrated that telemetry was being processed
again:

    Sysmon event:
    2026-08-28 12:12:07 UTC

    Wazuh alert:
    2026-08-28T19:12:08+0700

The approximately one-second processing difference confirmed that the
event successfully traversed the Wazuh pipeline.

---

# Final Assessment

The original Dashboard symptom was caused by an infrastructure/storage
condition rather than a failed detection rule.

The investigation followed the telemetry path:

    Endpoint
       ↓
    Sysmon
       ↓
    Wazuh Agent
       ↓
    Wazuh Manager
       ↓
    Wazuh Alert
       ↓
    Wazuh Indexer
       ↓
    Wazuh Dashboard

The investigation demonstrated that troubleshooting should proceed
layer by layer instead of immediately assuming that a missing Dashboard
event means there was no endpoint activity.

---

# Lessons Learned

## 1. "No Results" Does Not Necessarily Mean "No Activity"

A SOC analyst should distinguish between:

    No suspicious activity

and:

    No telemetry available

A missing event may indicate a telemetry pipeline failure.

---

## 2. Validate Telemetry at Multiple Layers

When a SIEM appears to stop receiving events, useful validation points
include:

    Endpoint event log
            ↓
    Agent service
            ↓
    Agent connectivity
            ↓
    Manager alerts/archives
            ↓
    Indexer health
            ↓
    Dashboard

This helps isolate where data stops flowing.

---

## 3. SIEM Health Is Part of Security Monitoring

Detection quality depends on the availability of the telemetry pipeline.

A well-written detection rule is not useful if the underlying
infrastructure cannot index and retain the events.

---

## 4. Disk Capacity Must Be Monitored

High disk utilization can affect SIEM availability.

In this case, disk pressure triggered the Indexer's flood-stage
protection mechanism and affected index write operations.

---

# SOC Analyst Relevance

Although this was not a malicious security incident, the investigation
demonstrates an important SOC L1 operational skill:

> Distinguishing a genuine absence of security activity from a failure
> in the monitoring pipeline.

The case also demonstrates basic troubleshooting across endpoint,
agent, manager, indexer, and dashboard components.

---

# Status

**Resolved**

### Root Cause

    Wazuh Indexer flood-stage disk watermark
            ↓
    read_only_allow_delete
            ↓
    indexing disruption
            ↓
    missing recent Dashboard data

### Remediation

    Free disk space
            ↓
    94% → 80%

### Validation

    New Sysmon telemetry
            ↓
    Wazuh Manager
            ↓
    Detection Rule 100101
            ↓
    alerts.json
            ↓
    indexing restored
