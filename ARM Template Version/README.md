---
services: Azure-Stack
platforms: PowerShell
author: chasat-ms & ashika789
---

# AzureStack-AdminPowerShell-OMSIntegration

A common ask from Microsoft Azure Stack customers is how can they integrate the operational and usage data from multiple Azure Stack deployments with OMS.  This project provides an example of how customers can build their own custom integration with OMS and PowerBI to visualize operational and usage data.

## Features

This project sample provides the follow features:

* Azure Stack alerts viewable through OMS
* Azure Stack capacity data (memory, storage, public IP) viewable through OMS
* Azure Stack version data per deployment viewable through OMS
* Azure Stack usage data available for PowerBI queries

## Getting Started

### Prerequisites

- Running and registered instance of Azure Stack (GA bits 170928.3 or higher)
- Marketplace syndication of the Windows Server 2016 - Eval VM Image
- Deployment GUID of Azure Stack system
- Subscription to Azure (OMS Log Analytics)
- Internet connection from Azure Stack OMS VM to Azure


### Installation

- Follow the detailed guidance in /docs/setup.md to deploy and configure a VM with scheduled tasks to upload data to OMS
- Follow the detailed guidance in /docs/dashboard.md to configure the PowerBI Dashboard for usage data analysis

## Screen Shots
### [Log Analytics Dashboard](https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration/blob/master/docs/screenshots/AzurePortalDashboard.PNG) 
### [Log Analytics Azure Stack Versions and Updates](https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration/blob/master/docs/screenshots/LogAnalyticsVersionsandUpdates.PNG)
### [Log Analytics Azure Stack Usage VM Size Hours by Clouds and Tenants](https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration/blob/master/docs/screenshots/LogAnalyticsUsageVMSizeHoursbyCloud.png )
### [Azure Dashboard Example](https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration/blob/master/docs/screenshots/AzurePortalDashboard.PNG)
