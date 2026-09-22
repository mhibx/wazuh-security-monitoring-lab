# Incident 10 — Endpoint Investigation with Velociraptor

## 1. Overview

This investigation demonstrates an endpoint-focused DFIR workflow using
Velociraptor to investigate PowerShell activity detected by Wazuh.

The investigation started from Wazuh alerts related to PowerShell and
SecEdit activity on the Windows endpoint X390. Velociraptor was then used
to collect endpoint evidence and correlate the findings with Sysmon
telemetry.

The objective was not to prove malicious activity solely from the initial
alert, but to determine the process lineage, execution context, related
file activity, and available endpoint telemetry.

---

## 2. Investigation Trigger

Wazuh generated alerts related to PowerShell and SecEdit activity.

Relevant telemetry included:

- Wazuh rule `92066` — SecEdit executed from a PowerShell process
- Wazuh rule `92021` — PowerShell used to delete files/directories
- Wazuh rule `92205` — PowerShell process created an executable/script file
- MITRE ATT&CK mapping included PowerShell (`T1059.001`) and file deletion
  (`T1070.004`) for the corresponding Wazuh detections.

The activity occurred on the Windows endpoint `X390`.

---

## 3. Initial Hypothesis

The initial alert involved PowerShell executing:

`secedit /export /cfg $env:TEMP\secpol.cfg`

followed by reading values from the exported security policy and removing
the temporary file.

Because PowerShell and temporary-file activity can appear in multiple
legitimate and malicious workflows, the activity was treated as requiring
investigation rather than immediately classified as malicious.

---

## 4. Velociraptor Investigation

### 4.1 Sysmon Collection

Velociraptor collected the endpoint's Sysmon event log using:

`Elastic.EventLogs.Sysmon`

The collection returned approximately 54,705 rows.

Relevant events were identified around:

`2026-09-18 08:45–08:46 WIB`

The Sysmon telemetry showed the following process lineage:

`wazuh-agent.exe`
→ `powershell.exe`
→ `SecEdit.exe`

The PowerShell process ran as:

`NT AUTHORITY\SYSTEM`

and its working directory was:

`C:\Program Files (x86)\ossec-agent\`

The observed PowerShell command exported the local security policy
to a temporary file, queried policy values, and removed the temporary file.

The corresponding SecEdit process was also executed as SYSTEM and was
launched by PowerShell. :contentReference[oaicite:1]{index=1}

---

## 5. PowerShell Event Log Collection

To obtain deeper PowerShell-specific evidence, two additional Velociraptor
artifacts were tested.

### ScriptBlock Logging

Artifact:

`Windows.EventLogs.PowerShellScriptblock`

Collection window:

`2026-09-18 08:40–08:50 WIB`

Result:

`0 rows`

### Module Logging

Artifact:

`Windows.EventLogs.PowerShellModule`

Collection window:

`2026-09-18 08:40–08:50 WIB`

Result:

`0 rows`

Both collections completed successfully, but neither returned relevant
PowerShell event records.

This means the investigation could not obtain additional ScriptBlock or
Module Logging evidence for the target activity.

---

## 6. Temporary File Investigation

Sysmon telemetry also recorded the creation of:

`C:\Windows\SystemTemp\__PSScriptPolicyTest_b3qxzalq.chr.ps1`

A Velociraptor `Windows.Search.FileFinder` collection was then performed
against the exact path.

Result:

`0 rows`

The file was therefore not present at the time of the live filesystem
collection.

This demonstrates an important DFIR distinction:

- Sysmon provides historical file-creation telemetry.
- FileFinder provides current filesystem state.

A file can therefore have historical creation evidence while no longer
being present on the endpoint.

---

## 7. Correlation

The available evidence can be summarized as:

Wazuh
→ detected PowerShell / SecEdit activity

Sysmon
→ provided process lineage and file-creation telemetry

Velociraptor
→ independently collected the Sysmon evidence

Velociraptor PowerShell ScriptBlock
→ no records available

Velociraptor PowerShell Module
→ no records available

Velociraptor FileFinder
→ temporary PowerShell file no longer present

The strongest correlation is the process lineage:

`wazuh-agent.exe`
→ `powershell.exe`
→ `SecEdit.exe`

The PowerShell process also executed from the Wazuh agent directory and
under the SYSTEM account. :contentReference[oaicite:2]{index=2}

This evidence is consistent with Wazuh-agent-driven security policy or
audit-related activity. However, the telemetry alone is not sufficient
to establish malicious or benign intent with absolute certainty.

---

## 8. Assessment

### Finding

The investigated PowerShell/SecEdit activity was associated with a
process chain originating from `wazuh-agent.exe` and running under
`NT AUTHORITY\SYSTEM`.

The observed command exported Windows security policy information,
queried selected policy values, and removed the temporary configuration
file.

No additional PowerShell ScriptBlock or Module Logging evidence was
available for the investigated time window.

The temporary `__PSScriptPolicyTest_*.ps1` file was historically observed
through Sysmon FileCreate telemetry but was not present during the later
Velociraptor filesystem search.

Based on the available evidence, the activity is **consistent with
agent-driven security monitoring activity**, rather than providing
direct evidence of an independent malicious PowerShell execution.

The investigation does not claim that malicious activity is impossible;
it records the evidence available and the remaining telemetry limitations.

---

## 9. Telemetry Gap

An important finding from this investigation is the difference between
endpoint telemetry sources.

Sysmon provided:

- Process creation
- Parent/child process relationships
- Command lines
- User context
- File creation events
- Process metadata

PowerShell ScriptBlock and Module Logging did not provide corresponding
records for this investigation window.

Therefore, the endpoint currently provides stronger visibility through
Sysmon than through PowerShell-specific event logging.

This represents a telemetry coverage limitation rather than a failure
of the Velociraptor collection itself.

---

## 10. Investigation Lessons

This investigation demonstrated several practical DFIR concepts:

1. An alert is an investigation starting point, not automatically a
   confirmed incident.

2. Process lineage can provide important context when investigating
   suspicious PowerShell activity.

3. Historical telemetry and current filesystem state are different
   sources of evidence.

4. An empty collection result is itself useful evidence when the
   collection completed successfully.

5. Endpoint investigation depends on the telemetry configured before
   the incident occurs.

6. Velociraptor can collect and correlate endpoint evidence, but it
   cannot recover telemetry that Windows did not generate or that is
   no longer available through the selected source.

---

## 11. MITRE ATT&CK

Relevant techniques observed in the investigation include:

- T1059.001 — Command and Scripting Interpreter: PowerShell
- T1070.004 — Indicator Removal: File and Directory Deletion

These mappings describe the observed behaviors and do not by themselves
indicate malicious intent.

---

## 12. Evidence

Primary evidence:

- Wazuh alerts
- Sysmon Event ID 1 — ProcessCreate
- Sysmon Event ID 11 — FileCreate
- Velociraptor Sysmon collection
- Velociraptor PowerShell ScriptBlock collection
- Velociraptor PowerShell Module collection
- Velociraptor FileFinder collection

Endpoint:

`X390`

Investigation window:

`2026-09-18 08:40–08:50 WIB`

---

## 13. Conclusion

The investigation successfully demonstrated an end-to-end endpoint
investigation workflow:

Wazuh detection
→ endpoint identification
→ Velociraptor collection
→ Sysmon process and file telemetry
→ evidence correlation
→ telemetry gap identification
→ contextual assessment

The investigation did not identify direct evidence of an independent
malicious PowerShell execution.

The main technical finding was that Sysmon provided sufficient process
and file telemetry for investigation, while PowerShell ScriptBlock and
Module Logging did not provide additional records for the investigated
window.
