# Windows Agent Deployment

## Objective

Connect a Windows endpoint to the Wazuh Manager.

## Installation

Generated installer from Wazuh Dashboard.

## Initial Problem

Agent failed to appear in the dashboard.

## Troubleshooting

- Network connectivity
- Port verification
- Firewall verification
- Agent configuration
- Service restart

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
