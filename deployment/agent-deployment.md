# Windows Agent Deployment

## Objective

Connect a Windows endpoint to the Wazuh Manager.

## Installation

Generated installer from Wazuh Dashboard.

![Agent Deploy](../screenshots/setup-05-wazuh-agentdeploy.png)

## Initial Problem

Agent failed to appear in the dashboard.

## Troubleshooting

- Network connectivity
- Port verification
- Firewall verification
- Agent configuration
- Service restart
![Firewall Troubleshoot](../screenshots/setup-06-wazuh-troublefirewall.png)
![Service Restart](../screenshots/setup-07-wazuh-troublereset.png)
## Root Cause

Incorrect Manager IP

```
0.0.0.0
```

Corrected to

```
192.168.1.7
```

## Result

Agent successfully connected and appeared as Active.

![Endpoint Monitor](../screenshots/setup-08-wazuh-endpointmonitor.png)
