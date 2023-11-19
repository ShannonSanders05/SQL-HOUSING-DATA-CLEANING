DROP TABLE IF EXISTS public.nashville_housing;

CREATE TABLE IF NOT EXISTS public.nashville_housing
(
    "UniqueID " bigint,
    "ParcelID" varchar COLLATE pg_catalog."default",
    "LandUse" varchar COLLATE pg_catalog."default",
    "PropertyAddress" text COLLATE pg_catalog."default",
    "SaleDate" date,
    "SalePrice" bigint,
    "LegalReference" varchar COLLATE pg_catalog."default",
    "SoldAsVacant" varchar COLLATE pg_catalog."default",
    "OwnerName" varchar COLLATE pg_catalog."default",
    "OwnerAddress" varchar COLLATE pg_catalog."default",
    "Acreage" numeric,
    "TaxDistrict" varchar COLLATE pg_catalog."default",
    "LandValue" numeric,
    "BuildingValue" numeric,
    "TotalValue" numeric,
    "YearBuilt" smallint,
    "Bedrooms" smallint,
    "FullBath" smallint,
    "HalfBath" smallint
)

SELECT *
FROM nashville_housing

-- PROPERTY ADDRESS POPULATE

SELECT *
FROM nashville_housing
ORDER BY nashville_housing."ParcelID"

SELECT a."ParcelID",a."PropertyAddress",b."ParcelID",b."PropertyAddress", COALESCE (a."PropertyAddress",b."PropertyAddress")
FROM nashville_housing a
JOIN nashville_housing b
	ON a."ParcelID" = b."ParcelID"
	AND a."UniqueID " <> b."UniqueID "
WHERE a."PropertyAddress" IS NULL

UPDATE nashville_housing
SET "PropertyAddress" = COALESCE (a."PropertyAddress",b."PropertyAddress")
FROM nashville_housing a
JOIN nashville_housing b
	ON a."ParcelID" = b."ParcelID"
	AND a."UniqueID " <> b."UniqueID "
WHERE a."PropertyAddress" IS NULL

-- BREAKING OUT PROPERTY ADDRESS

SELECT "PropertyAddress"
FROM nashville_housing

SELECT 
SUBSTRING("PropertyAddress",1, POSITION(',' IN "PropertyAddress")-1) AS Address,
SUBSTRING("PropertyAddress", POSITION(',' IN "PropertyAddress")+1, LENGTH("PropertyAddress") ) AS Address
FROM nashville_housing

ALTER TABLE nashville_housing
ADD "PropertySplitAddress" text

UPDATE nashville_housing
SET "PropertySplitAddress" = SUBSTRING("PropertyAddress",1, POSITION(',' IN "PropertyAddress")-1)

ALTER TABLE nashville_housing
ADD "PropertySplitCity" text

UPDATE nashville_housing
SET "PropertySplitCity" = SUBSTRING("PropertyAddress", POSITION(',' IN "PropertyAddress")+1, LENGTH("PropertyAddress") )


-- BREAKING OUT OWNER ADDRESS

SELECT "OwnerAddress"
FROM nashville_housing

SELECT
SPLIT_PART("OwnerAddress",',',3),
SPLIT_PART("OwnerAddress",',',2),
SPLIT_PART("OwnerAddress",',',1)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD "OwnerSplitAddress" text

UPDATE nashville_housing
SET "OwnerSplitAddress" = SPLIT_PART("OwnerAddress",',',3)

ALTER TABLE nashville_housing
ADD "OwnerSplitCity" text

UPDATE nashville_housing
SET "OwnerSplitCity" = SPLIT_PART("OwnerAddress",',',2)

ALTER TABLE nashville_housing
ADD "OwnerSplitState" text

UPDATE nashville_housing
SET "OwnerSplitState" = SPLIT_PART("OwnerAddress",',',1)

-- SOLD AS VACANT CLEANING

SELECT DISTINCT("SoldAsVacant"), COUNT("SoldAsVacant")
FROM nashville_housing
GROUP BY nashville_housing."SoldAsVacant"
ORDER BY 2

SELECT "SoldAsVacant",
CASE
	WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
	WHEN "SoldAsVacant" = 'N' THEN 'No'
	ELSE "SoldAsVacant"
 END AS "SoldAsVacantFixed"
FROM nashville_housing

UPDATE nashville_housing
SET "SoldAsVacant" = CASE
	WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
	WHEN "SoldAsVacant" = 'N' THEN 'No'
	ELSE "SoldAsVacant"
 END
 
--REMOVING DUPLICATES

WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER () OVER
	(
		PARTITION BY "ParcelID",
					"PropertyAddress",
					"SalePrice",
					"SaleDate",
					"LegalReference"
					ORDER BY
						"UniqueID "
	) row_num
FROM nashville_housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1

WITH nashville_housing_deleted AS
(DELETE FROM nashville_housing returning *), -- 1st step
nashville_housing_inserted AS
(
SELECT *,
	ROW_NUMBER () OVER
	(
		PARTITION BY "ParcelID",
					"PropertyAddress",
					"SalePrice",
					"SaleDate",
					"LegalReference"
					ORDER BY
						"UniqueID "
	) "row_num"
FROM nashville_housing
) -- 2nd step
INSERT INTO nashville_housing 
SELECT
	"UniqueID ",
	"ParcelID",
	"LandUse",
	"PropertyAddress",
	"SaleDate",
	"SalePrice",
	"LegalReference",
	"SoldAsVacant",
	"OwnerName",
	"OwnerAddress",
	"Acreage",
	"TaxDistrict",
	"LandValue",
	"BuildingValue",
	"TotalValue",
	"YearBuilt",
	"Bedrooms",
	"FullBath",
	"HalfBath",
	"PropertySplitAddress",
	"PropertySplitCity",
	"OwnerSplitAddress",
	"OwnerSplitCity",
	"OwnerSplitState"
FROM nashville_housing_inserted 
WHERE "row_num" = 1; -- 3rd step 

-- DROPPING UNUSED COLUMN

ALTER TABLE nashville_housing
DROP COLUMN "OwnerAddress"

ALTER TABLE nashville_housing
DROP COLUMN "TaxDistrict"

ALTER TABLE nashville_housing
DROP COLUMN "PropertyAddress"

SELECT *
FROM nashville_housing