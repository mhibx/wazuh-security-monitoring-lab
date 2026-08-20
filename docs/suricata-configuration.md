# Suricata Configuration

## Objective

Configure Suricata to monitor network traffic on the Ubuntu server and generate useful security telemetry.

The configuration prepares Suricata to function as the network detection layer of the Wazuh security monitoring lab.

Suricata is responsible for inspecting network traffic and generating events, while Wazuh will later be used to collect, centralize, and investigate those events.

---

## Configuration File

The main Suricata configuration file is:

```text
/etc/suricata/suricata.yaml
```

The configuration controls several important aspects of the Suricata sensor, including:

- Network interfaces
- Network address configuration
- Rule paths
- Detection settings
- Logging
- Event output
- EVE JSON logging

The configuration was adjusted from the default installation to match the lab environment.

---

## Network Interface

Suricata needs to monitor the network interface through which the relevant traffic passes.

Available network interfaces can be identified using:

```bash
ip addr
```

The interface used by Suricata should correspond to the active network interface on the Ubuntu server.

Before applying the configuration, the interface should be verified to ensure that Suricata is monitoring the intended network traffic.

![Network Interface](../screenshots/suricata-05-network-interface.png)

---

## HOME_NET

Suricata uses the `HOME_NET` variable to define the network considered to be the local or protected environment.

The value should match the network used by the lab.

Example:

```yaml
vars:
  address-groups:
    HOME_NET: "[192.168.1.0/24]"
```

The actual value should reflect the network configuration of the lab environment.

Defining `HOME_NET` correctly is important because Suricata uses this information when evaluating network events and applying detection rules.

---

## Rule Configuration

Suricata loads detection rules from its configured rule directory.

The rule path is defined in:

```text
/etc/suricata/suricata.yaml
```

The rule configuration determines which signatures Suricata uses to identify potentially suspicious network activity.

The initial lab configuration uses the existing Suricata rule set as the foundation for network detection.

Custom rules can be added later when developing organization-specific detections.

---

## EVE JSON Logging

One of the most important outputs for this lab is:

```text
eve.json
```

The file is located at:

```text
/var/log/suricata/eve.json
```

EVE JSON provides structured event data that can be consumed by other security monitoring tools.

Example configuration:

```yaml
outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
```

The EVE output can contain different event types, including:

- Alerts
- DNS events
- HTTP events
- TLS events
- Flow events
- Network protocol information

The exact event types depend on the enabled Suricata configuration.

---

## Logging Architecture

The relevant telemetry flow is:

```text
Network Traffic
       |
       v
   Suricata
       |
       v
   Detection Rules
       |
       v
    eve.json
       |
       v
   Wazuh Agent
       |
       v
  Wazuh Manager
```

This separates the responsibilities of each component.

Suricata performs network traffic inspection.

Wazuh performs centralized collection, correlation, alerting, and investigation.

---

## Configuration Validation

After making configuration changes, the configuration should be validated before restarting the service.

Run:

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

A successful validation confirms that Suricata can load the configuration without syntax or configuration errors.

![Configuration Validation](../screenshots/suricata-06-configuration-validation.png)

---

## Service Restart

After successful validation, restart Suricata to apply the configuration:

```bash
sudo systemctl restart suricata
```

Verify the service:

```bash
sudo systemctl status suricata
```

The service should report:

```text
Active: active (running)
```

![Suricata Restart](../screenshots/suricata-07-service-restart.png)

---

## Log Verification

After Suricata is running, verify that the expected log files are being created:

```bash
sudo ls -lah /var/log/suricata/
```

The EVE JSON log can be monitored using:

```bash
sudo tail -f /var/log/suricata/eve.json
```

At this stage, the goal is to confirm that Suricata is producing structured telemetry successfully.

![EVE JSON](../screenshots/suricata-08-eve-json.png)

---

## Configuration Result

The Suricata sensor is configured and ready to monitor network activity.

The configuration provides:

- Network interface monitoring
- Local network identification
- Detection rule loading
- Structured EVE JSON logging
- Integration readiness for Wazuh

The next stage is to generate controlled network activity and verify whether Suricata detects the expected behavior.

---

## Skills Demonstrated

- Suricata Configuration
- Network Interface Analysis
- IDS Configuration
- EVE JSON Logging
- Detection Rule Management
- Linux Service Management
- Configuration Validation
- Network Security Monitoring
- SIEM Integration Preparation

---

## Evidence

The following evidence should be collected during configuration:

```text
screenshots/
├── suricata-05-network-interface.png
├── suricata-06-configuration-validation.png
├── suricata-07-service-restart.png
└── suricata-08-eve-json.png
```

These screenshots document the configuration and verification process from network interface identification through successful telemetry generation.
