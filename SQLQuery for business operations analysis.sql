--Query to answer if there is a digital shift.
SELECT	A.[OrderDate],
		A.[OnlineOrderFlag],
		A.[CustomerID],
		B.[SalesOrderID],
		B.[SalesOrderDetailID],
		B.[OrderQty],
		B.[UnitPrice],
		B.[UnitPriceDiscount],
		B.[LineTotal] AS Revenue,
		C.[ProductID],
		C.[Name] AS ProductName,
		C.[StandardCost],
		C.[ListPrice],
		C.[DaysToManufacture],
		D.[ProductSubcategoryID],
		D.[Name] AS ProductSubcategoryName,
		E.[ProductCategoryID],
		E.[Name] AS ProductCategoryName,
		F.[TerritoryID],
		F.[Name] AS SalesTerritory,
		F.[CountryRegionCode],
		F.[Group],
		G.*,
CASE WHEN A.[OnlineOrderFlag] = 1 THEN 'Online' ELSE 'Reseller' END AS Sales_Channel,
CASE 
WHEN F.[Name] = 'Northwest' THEN 'Northwest US'
WHEN F.[Name] = 'Northeast' THEN 'Northeast US'
WHEN F.[Name] = 'Central' THEN 'Central US'
WHEN F.[Name] = 'Southwest' THEN 'Southwest US'
WHEN F.[Name] = 'Southeast' THEN 'Southeast US'
ELSE F.[Name] END AS Region,
CASE WHEN G.[HouseOwnerFlag] = 1 THEN 'House Owner' ELSE 'Non-house owner' END AS House_NonHouseOwner
FROM [Sales].[SalesOrderHeader] AS A
LEFT JOIN [Sales].[SalesOrderDetail] AS B
ON A.[SalesOrderID] = B.[SalesOrderID]
LEFT JOIN [Production].[Product] AS C
ON B.[ProductID] = C.[ProductID]
LEFT JOIN [Production].[ProductSubcategory] AS D
ON C.[ProductSubcategoryID] = D.[ProductSubcategoryID]
LEFT JOIN [Production].[ProductCategory] AS E
ON D.[ProductCategoryID] = E.[ProductCategoryID]
LEFT JOIN [Sales].[SalesTerritory] AS F
ON A.[TerritoryID] = F.[TerritoryID]
LEFT JOIN [AdventureWorksDW2019].[dbo].[DimCustomer] AS G
ON A.[CustomerID] = G.[CustomerKey]


-- Query to answer where costs are too high and pricing inadequate.

SELECT AVG	(A.[LineTotal]) AS AvgRevenue,
		AVG (B.[ListPrice]) AS AvgListPrice,
		B.[Name] AS ProductName,
		C.[OnlineOrderFlag],
		D.[Name] AS SalesTerritory,
CASE WHEN C.[OnlineOrderFlag] = 1 THEN 'Online' ELSE 'Reseller' END AS Sales_Channel,
CASE 
WHEN D.[Name] = 'Northwest' THEN 'Northwest US'
WHEN D.[Name] = 'Northeast' THEN 'Northeast US'
WHEN D.[Name] = 'Central' THEN 'Central US'
WHEN D.[Name] = 'Southwest' THEN 'Southwest US'
WHEN D.[Name] = 'Southeast' THEN 'Southeast US'
ELSE D.[Name] END AS Region
FROM [Sales].[SalesOrderDetail] AS A
LEFT JOIN [Production].[Product] AS B
ON A.[ProductID] = B.[ProductID]
LEFT JOIN [Sales].[SalesOrderHeader] AS C
ON A.[SalesOrderID] = C.[SalesOrderID]
LEFT JOIN [Sales].[SalesTerritory] AS D
ON C.[TerritoryID] = D.[TerritoryID]
WHERE A.[LineTotal] < B.[ListPrice]
GROUP BY B.[Name], C.[OnlineOrderFlag], D.[Name]
ORDER BY B.[Name]


-- Query to answer if materials needed for manufacturing are received on time.

SELECT	A. [ProductID],
		A.[Name] AS ProductName,
		B. AverageLeadTime,
		C.[Name] AS VendorName
FROM [Production].[Product] AS A
LEFT JOIN [Purchasing].[ProductVendor] AS B
ON A.[ProductID] = B.[ProductID]
LEFT JOIN [Purchasing].[vVendorWithContacts] AS C
ON B.[BusinessEntityID] = C.[BusinessEntityID]
WHERE [AverageLeadTime] <> 0
GROUP BY A.[ProductID], A.[Name], B. [AverageLeadTime], C.[Name]
ORDER BY [AverageLeadTime] ASC


--Query to answer the average time to deliver products.

SELECT [SalesOrderID],
		[OrderDate],
		[DueDate],
		[ShipDate],
		DATEDIFF (DD, [OrderDate], [DueDate]) AS [DaysToDeliver],
		DATEDIFF (DD, [OrderDate],[ShipDate]) AS [DaysToShip]
FROM [Sales].[SalesOrderHeader] 


--Query to answer the average time to manufacture.

SELECT	A.[Name] AS ProductName,
		B.[Name] AS ProductSubcategory,
		C.[Name] as ProductCategory,
		D.[ScheduledStartDate],
		D.[ScheduledEndDate],
		D.[ActualStartDate],
		D.[ActualEndDate],
		DATEDIFF (DD, [ScheduledStartDate], [ScheduledEndDate]) AS [ScheduledDaysToManufacture],
		DATEDIFF (DD, [ActualStartDate], [ActualEndDate]) AS [ActualDaysToManufacture]
FROM [Production].[Product] AS A
LEFT JOIN [Production].[ProductSubcategory] AS B
ON A.[ProductSubcategoryID] = B.[ProductSubcategoryID]
LEFT JOIN [Production].[ProductCategory] AS C
ON B.[ProductCategoryID] = C.[ProductCategoryID]
LEFT JOIN [Production].[WorkOrderRouting] AS D
ON A.[ProductID] = D.[ProductID]
WHERE DATEDIFF (DD, [ActualStartDate], [ActualEndDate]) <> 0
AND C.[Name] IS NOT NULL
ORDER BY ActualDaysToManufacture ASC


--Query to answer if items being purchased from vendors are being rejected.
SELECT A.[PurchaseOrderID],
		A.[OrderQty],
		A.[ReceivedQty],
		A.[RejectedQty],
		A.[StockedQty],
		C.[Name] AS VendorName
FROM [Purchasing].[PurchaseOrderDetail] AS A
LEFT JOIN [Purchasing].[ProductVendor] AS B
ON A.[ProductID] = B.[ProductID]
LEFT JOIN [Purchasing].[vVendorWithContacts] AS C
ON B.[BusinessEntityID] = C.[BusinessEntityID]
WHERE [RejectedQty] <> 0
GROUP BY C.[Name], A.[PurchaseOrderID], A.[OrderQty], A.[ReceivedQty], A.[RejectedQty], A.[StockedQty]
ORDER BY A.[RejectedQty] ASC



-- Query to answer how many products purchased from vendors are being scrapped and the scrap reasons.
SELECT A.[ProductID],
		A.[Name] AS ProductName,
		B.[ScrappedQty],
		C.[Name] AS ScrapReason	
FROM [Production].[Product] AS A
LEFT JOIN [Production].[WorkOrder] AS B
ON A.[ProductID] = B.[ProductID]
LEFT JOIN [Production].[ScrapReason] AS C
ON B.[ScrapReasonID] = C.[ScrapReasonID]
WHERE B.[ScrappedQty] <> 0
GROUP BY C.[Name], A.[ProductID], A.[Name], B.[ScrappedQty]
ORDER BY B.[ScrappedQty] DESC