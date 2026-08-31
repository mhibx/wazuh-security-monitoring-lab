# Wazuh Indexer Disk Watermark Troubleshooting

## Overview

During the operation of the Wazuh Security Monitoring Lab, the Wazuh Indexer generated the following warning:

```text
indexer-connector: WARNING: Indexer request failed - type:
'cluster_block_exception', reason:
'index [wazuh-states-inventory-interfaces-mhibx] blocked by:
[TOO_MANY_REQUESTS/12/disk usage exceeded flood-stage watermark,
index has read-only-allow-delete block]'
```

The Wazuh Indexer service itself was still running, but some Wazuh data was not behaving normally in the Dashboard.

This investigation focused on determining whether the issue was caused by:

- filesystem capacity exhaustion
- inode exhaustion
- Wazuh Indexer storage
- Wazuh Manager storage
- Suricata logs
- virtual machine images
- user-level files

The issue was investigated from the filesystem level before making changes to the Wazuh Indexer configuration.

---

## Symptoms

The primary symptom was abnormal Wazuh Dashboard data behavior.

The Wazuh Indexer service was still running:

```bash
sudo systemctl status wazuh-indexer --no-pager
```

Example status:

```text
wazuh-indexer.service - wazuh-indexer
Active: active (running)
```

However, the Indexer reported:

```text
disk usage exceeded flood-stage watermark
index has read-only-allow-delete block
```

This is important because a running Indexer service does not necessarily mean that indexing operations are healthy.

When disk usage reaches the configured flood-stage watermark, OpenSearch/Wazuh Indexer can protect the node by placing affected indices into a `read_only_allow_delete` state.

---

## Initial Filesystem Investigation

The root filesystem was checked first:

```bash
df -h
```

Initial result:

```text
/dev/sda2       218G  193G   15G  94% /
```

The root filesystem was therefore critically close to full capacity.

The inode usage was also checked:

```bash
df -i
```

Result:

```text
/dev/sda2       14589952 1511123 13078829   11% /
```

Only approximately 11% of the available inodes were being used.

### Finding

The problem was related to **disk space**, not inode exhaustion.

---

## Identify Major Storage Consumers

The root filesystem was investigated layer by layer:

```bash
sudo du -xhd1 / 2>/dev/null | sort -h
```

Relevant results:

```text
5.0G    /opt
13G     /usr
59G     /var
111G    /home
191G    /
```

The largest areas were therefore:

- `/var`
- `/home`

Further investigation was performed on both locations.

---

## Investigating `/var`

```bash
sudo du -xhd1 /var 2>/dev/null | sort -h
```

Relevant results:

```text
8.3G    /var/log
14G     /var/ossec
36G     /var/lib
59G     /var
```

This showed that several independent components were consuming significant storage.

---

## Wazuh Indexer Storage

The Wazuh Indexer data directory was checked:

```bash
sudo du -xhd1 /var/lib/wazuh-indexer 2>/dev/null | sort -h
```

Result:

```text
186M    /var/lib/wazuh-indexer
```

The Wazuh Indexer data directory itself was therefore relatively small compared with the total disk usage.

### Finding

The flood-stage condition was **not primarily caused by the Wazuh Indexer data directory itself**.

---

## Wazuh Manager Storage

The Wazuh Manager directory was investigated:

```bash
sudo du -xhd2 /var/ossec 2>/dev/null | sort -h | tail -30
```

A significant amount of storage was found under:

```text
14G     /var/ossec
13G     /var/ossec/queue
12G     /var/ossec/queue/vd
12G     /var/ossec/queue/vd/feed
```

Additional storage was present in:

```text
978M    /var/ossec/queue/indexer
566M    /var/ossec/logs
386M    /var/ossec/logs/archives
175M    /var/ossec/logs/alerts
```

### Finding

The Wazuh Manager's vulnerability-detection feed storage was one of the major consumers of disk space.

In particular:

```text
/var/ossec/queue/vd/feed
```

was approximately 12 GB.

The directory was therefore identified as an important storage contributor, but it was not immediately deleted because it is part of Wazuh's operational data.

---

## Investigating Suricata Logs

Because the lab also uses Suricata, its logs were investigated:

```bash
sudo du -sh /var/log/suricata/* 2>/dev/null | sort -h
```

The largest files were:

```text
1.2G    /var/log/suricata/fast.log
6.1G    /var/log/suricata/eve.json
```

The complete Suricata log directory was approximately:

```text
7.5G    /var/log/suricata
```

### Finding

Suricata logging was another major contributor to disk consumption.

The `eve.json` file alone had grown to approximately 6.1 GB.

This is expected in a security monitoring lab because Suricata can generate a high volume of telemetry, but log retention must be controlled to prevent the monitoring stack from exhausting the host filesystem.

---

## Investigating Virtual Machine Storage

The libvirt storage directory was also checked:

```bash
sudo du -xhd2 /var/lib/libvirt 2>/dev/null | sort -h | tail -30
```

The VM image directory consumed:

```text
24G     /var/lib/libvirt/images
```

The image itself was:

```text
-rw------- 1 root root 26G debian13.qcow2
```

### Finding

The Debian VM image was another significant consumer of the root filesystem.

This file was not deleted because it is part of the lab environment.

---

## Investigating User Storage

The user's home directory was investigated:

```bash
sudo du -xhd1 /home/wafi 2>/dev/null | sort -h
```

The largest areas included:

```text
22G     /home/wafi/Downloads
5.3G    /home/wafi/.cache
4.8G    /home/wafi/Wordlists
4.1G    /home/wafi/go
3.7G    /home/wafi/snap
67G     /home/wafi/.local
111G    /home/wafi
```

The `.local/share` directory was then investigated:

```bash
du -xhd1 /home/wafi/.local/share 2>/dev/null | sort -h
```

Significant results included:

```text
28G     /home/wafi/.local/share/Trash
36G     /home/wafi/.local/share/Steam
67G     /home/wafi/.local/share
```

### Finding

A major amount of storage was being consumed by the desktop Trash:

```text
~/.local/share/Trash
```

approximately **28 GB**.

This was safe to remove because it consisted of files that had already been moved to Trash.

---

## Remediation

The Trash was permanently removed:

```bash
rm -rf ~/.local/share/Trash/*
```

The filesystem was then checked again:

```bash
df -h /
```

After cleanup:

```text
/dev/sda2       218G  165G   42G  80% /
```

Disk utilization therefore decreased from:

```text
94%  ->  80%
```

and available space increased from approximately:

```text
15 GB -> 42 GB
```

This provided a significant safety margin for the Wazuh monitoring stack.

---

## Validate Index Read-Only State

After freeing disk space, the Indexer state was checked using the Wazuh Indexer API.

The query used was:

```bash
curl -k -u '<WAZUH_CREDENTIALS>' \
"https://localhost:9200/_all/_settings?filter_path=*.settings.index.blocks.read_only_allow_delete"
```

The response was:

```text
{}
```

This indicated that no `read_only_allow_delete` blocks were returned by this query at the time of validation.

### Important Note

The original warning:

```text
disk usage exceeded flood-stage watermark
index has read-only-allow-delete block
```

should be treated as evidence of the condition that occurred earlier.

A historical warning does not necessarily mean that the index remains blocked after disk space has been recovered.

---

## Validation of Wazuh Telemetry

The Wazuh Manager was also validated at the telemetry level.

For example, the custom account-discovery detection was still generating alerts:

```bash
sudo tail -20 /var/ossec/logs/alerts/alerts.json | \
jq -c 'select(.rule.id=="100101")'
```

The resulting event contained:

```text
rule.id: 100101
rule.description: Account discovery using net user from PowerShell
agent.name: X390
```

The underlying Sysmon telemetry showed:

```text
Image: C:\Windows\System32\net.exe
CommandLine: "C:\WINDOWS\system32\net.exe" user
ParentImage: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
User: X390\tempo
```

This confirmed that telemetry was still reaching the Wazuh Manager and that the custom detection pipeline was functioning.

---

## Additional Sysmon Validation

The archived telemetry was also inspected:

```bash
sudo tail -50 /var/ossec/logs/archives/archives.json | \
jq -c 'select(.data.win.system.providerName=="Microsoft-Windows-Sysmon")'
```

A Sysmon Event ID 2 record was observed:

```text
RuleName: T1099
Image: C:\Users\tempo\AppData\Local\Discord\app-1.0.9253\Discord.exe
TargetFilename: C:\Users\tempo\AppData\Roaming\discord\Network\921acb93-6ad7-4fd0-94ba-c8531c58b69d.tmp
```

This provided additional evidence that Sysmon events were being collected by Wazuh.

---

## Root Cause

The incident was caused by **overall root filesystem pressure**, rather than a failure of the Wazuh Indexer service itself.

Multiple components contributed to the disk usage:

| Component | Approx. Size | Role |
|---|---:|---|
| `/var/ossec/queue/vd/feed` | 12 GB | Wazuh vulnerability-detection feed |
| `/var/log/suricata` | 7.5 GB | Suricata telemetry/logs |
| `/var/lib/libvirt/images` | 24 GB | Virtual machine image |
| `~/.local/share/Trash` | 28 GB | Deleted desktop files |
| `/var/lib` | 36 GB | System/application data |
| `/home/wafi` | 111 GB | User data |

The immediate remediation was to remove approximately 28 GB of unnecessary Trash data.

---

## Lessons Learned

### 1. A running service can still be unhealthy

The Wazuh Indexer remained:

```text
Active: active (running)
```

but indexing operations were affected by the disk watermark.

Service status alone is therefore insufficient when troubleshooting a SIEM.

---

### 2. Investigate the filesystem before changing application configuration

Instead of immediately modifying the Wazuh Indexer configuration or watermark settings, the investigation started with:

```text
Filesystem
    |
    +-- Disk capacity
    |
    +-- Inode usage
    |
    +-- /var
    |     +-- Wazuh
    |     +-- Suricata
    |     +-- Logs
    |     +-- libvirt
    |
    +-- /home
          +-- Cache
          +-- Downloads
          +-- Trash
          +-- Steam
```

This avoided treating the symptom while ignoring the underlying storage problem.

---

### 3. Security telemetry can become a storage problem

Security monitoring components such as:

- Wazuh
- Suricata
- Sysmon
- vulnerability feeds
- archived events

can generate significant amounts of data.

A security lab therefore needs both:

```text
Detection Engineering
+
Storage / Log Retention Management
```

---

## Recommended Preventive Actions

The lab should periodically review storage usage:

```bash
df -h
```

and identify large directories:

```bash
sudo du -xhd1 /var 2>/dev/null | sort -h
sudo du -xhd1 /home/wafi 2>/dev/null | sort -h
```

Suricata log growth should also be monitored:

```bash
sudo du -sh /var/log/suricata
```

Wazuh storage should be reviewed periodically:

```bash
sudo du -xhd2 /var/ossec 2>/dev/null | sort -h | tail -30
```

For a long-running lab, log rotation and retention policies should be configured rather than relying on manual cleanup.

---

## Final Status

After cleanup:

```text
Root filesystem:
94% used -> 80% used

Available space:
15 GB -> 42 GB
```

The Wazuh Indexer remained operational, and the read-only index block query returned:

```text
{}
```

Wazuh telemetry was subsequently verified through both:

- custom Wazuh alerts
- raw Sysmon EventChannel telemetry

The incident demonstrated that the Indexer warning was a consequence of host-level disk pressure and that filesystem-level investigation was necessary to identify the actual storage consumers.
