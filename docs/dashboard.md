# Overview

There are 5 numbers on each tile. The biggest number is the quantity of each measure in the period specified by the time slicer. The number immediately below it is the change between the previous period and the current period. The previous period has the same length as the current period and is immediately prior to the current selected time period chronologically. 
The bottom two numbers are the percent change from the previous period calculated as: 
(current period quantity - previous period quantity) / previous period quantity
and the average percent change in quantity for the 3 previous periods. 

There are three slicers/filters on the right side: `Deployment Guid`, `Tenant(s)`, and `SubscriptionId`. `Deployment Guid` uniquely identifies each Azure Stack instance and `Tenant(s)` is an identifier for each tenant, while `SubscriptionId` is unique for each subscription. The filters can be used to see metrics on the page at the tenant and deployment level. 

### VM Core Hours

The number of core hours consumed during the time period specified by the time slicer. 

### Virtual Machines

The number of VMs that are running at the **end** of the period specified by the time slicer. 

### Virtual Cores

The number of virtual cores in use by running VMs at the **end** of the period specified by the time slicer. 

### Memory Utilization

Currently not implemented, but can be enabled with Capacity data from OMS. 

### Total Storage Consumed

Total storage consumed in Gbs at the **end** of the period specified by the time slicer. Includes BlockBlobs, PageBlobs, Queues, and Tables. 

### Ingress

Amount of data (in Gbs) entering into storage during the specified period. Includes Tables, Blobs, and Queues. 

### Egress

Amount of data (in Gbs) exiting storage during the specified period. Includes Tables, Blobs, and Queues. 

### Storage Capacity

Currently not implemented, but can be enabled with Capacity data from OMS. 

# Tenant Breakdown

This report breaks down usage by tenants. One should select a meter on the right to look at usage in that category across tenants. 

There are four tiles at the top. The first tile from the left is the number of tenants who used the service described by the selected meter in the time frame specified. The second tile is the total quantity consumed within the timeframe by all the tenants. The third tile is the total quantity consumed within the immediately previous timeframe of the same length by all the tenants. The last tile is the percent change in quantity between the current time frame and the previous time frame.  

Note: You must select a meter for the numbers to make sense. Otherwise, Power BI automatically aggregate quantity across meters and since the units for the meters are different, The quantity measure would not make any sense. 

In the table, each tenant is assigned a rank by quantity (from most to least) and a prev rank that denotes the rank last period. Avg percent change is calculated over the previous 3 periods, of the same period length. 

At the bottom of the report, there is usage proportion by the top tenants (up to 10) to give an idea of the footprints of individual tenants. 

# VM Core Hours By VM Sizes

The top left graph is the breakdown of total VM core hours consumed in the time frame by different VM sizes. If there are more than 10 VM sizes used in the period, the graph only takes the top 10 VM sizes by the VM core hours. 

The top right graph is a comparison of percent change in VM core hours for each of the VM sizes this current period with the averge percent change in VM core hours over the past three periods of the same length. When more than 7 VM sizes were in use during the selected time period, only the growth rate for the top 7 VM sizes by VM core hours are shown. 

The bottom graph shows the count in VM core hours consumed by each of the VM sizes over time. Each data point on the graph represent the sum of all VM core hours consumed during that time. Similarly, only the top 7 VM sizes by VM core hours are shown on the graph. 

To modify the maximum number of VM sizes to show on each graph, click on the individual graph and open the Filters Pane on the right. Under Visual level filters, click AdditionalInfo_s and you can modify how many items to show at a maximum. 

This report can be viewed at an overall aggregate level, by each individual azure stack, and by tenant. To filter down into individual azure stacks, use the DeploymentGuid_s filter on the right. To filter down into individual tenants, use the Tenant_s filter on the right. If nothing is selected in the filters, the default view is the aggreggated data across all azure stacks from the data source. 

# Number of VMs By VM Sizes

Same as the previous visual, except now it is broken down into count of VMs used, as supposed to count of VM core hours consumed. 

# Service Trend

This view is for analysis of different services by usage. On the left side, you can specify the date range and choose a meter. 

Note: You must select a meter for the graph to make sense. Otherwise, Power BI automatically aggregate quantity across meters and since the units for the meters are different, The quantity measure would not make any sense. 

The line graph shows the usage trend across that time period and the unit for the selected meter is shown in the upper right corner of the graph. The donut chart denotes the proportion of the filtered data when compared with all the usage data falling under the meter selected. 

The table in the top left corner specifies all the resource names that contribute to the quantity shown in the graph for the selected meter in that time frame. For example, if you have a Windows VM called vm1 running on July 19th and you have the time frame include July 19th and the selected meter be Windows VM Size Hours, then vm1 will show up in the top left corner. 

There are four additional slicers allowing for further analysis. You can look at the data at a per stack level (DeploymentGuid_g), per tenant level (Tenant_s), per subscription level (SubscriptionId), or a per resource level (ResourceName_s, i.e. one single VM). When a filter is selected, the top donut chart shows the usage proportion of the selected filter. 

# Capacity Planning

Not implemented. Can be enabled with Capacity data from OMS. 
