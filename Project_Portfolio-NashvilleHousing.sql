/*
Nashville Housing
Focused on Cleaning the Data
*/

SELECT * FROM Portfolio_Project.dbo.NashvilleHousing

--Standardizing the Data
--NOTE now there are two date columns use the converted one
SELECT SaleDate, CONVERT(date,SaleDate) 
	FROM Portfolio_Project.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
	ADD SaleDateConverted date

UPDATE NashvilleHousing
	SET SaleDateConverted = CONVERT(date,SaleDate)

--Populate Property Address Data
SELECT * FROM Portfolio_Project.dbo.NashvilleHousing
	ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
		FROM Portfolio_Project.dbo.NashvilleHousing AS a
	JOIN Portfolio_Project.dbo.NashvilleHousing AS b 
		ON a.ParcelID=b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
	WHERE a.PropertyAddress IS NULL

UPDATE a
	SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress) 
		FROM Portfolio_Project.dbo.NashvilleHousing AS a
	JOIN Portfolio_Project.dbo.NashvilleHousing AS b 
		ON a.ParcelID=b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
	WHERE a.PropertyAddress IS NULL

--Breaking out Address into Individual Columns (Address,City, State)
SELECT PropertyAddress FROM Portfolio_Project.dbo.NashvilleHousing

--Updating Property Address
SELECT
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS City
			FROM Portfolio_Project.dbo.NashvilleHousing  

ALTER TABLE NashvilleHousing
	ADD PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
	SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
	PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

SELECT * FROM Portfolio_Project.dbo.NashvilleHousing

--Updating Owner Address
SELECT OwnerAddress FROM Portfolio_Project.dbo.NashvilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
		FROM Portfolio_Project.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
	ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
	SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT * FROM Portfolio_Project.dbo.NashvilleHousing

--Sold as Vacant (Making sure SoldAsVacant values are unified via Case)
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM Portfolio_Project.dbo.NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY 2

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
	FROM Portfolio_Project.dbo.NashvilleHousing

UPDATE NashvilleHousing
	SET SoldAsVacant = CASE 
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

--Remove Duplicates via CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SalePrice, 
				 SaleDate, 
				 LegalReference
				 ORDER BY UniqueID) ROW_NUM
		FROM Portfolio_Project.dbo.NashvilleHousing
	--ORDER BY ParcelID)
	)
SELECT * FROM RowNumCTE
	WHERE row_num > 1
	ORDER BY PropertyAddress

--NOTE: To delete I just replace SELECT with DELETE and ran all the data

--Delete Unused Columns
SELECT * FROM Portfolio_Project.dbo.NashvilleHousing

ALTER TABLE Portfolio_Project.dbo.NashvilleHousing
	DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
ALTER TABLE Portfolio_Project.dbo.NashvilleHousing
	DROP COLUMN SaleDate