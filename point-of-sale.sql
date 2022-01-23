-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Jan 23, 2022 at 03:47 AM
-- Server version: 10.6.5-MariaDB-1:10.6.5+maria~focal
-- PHP Version: 7.4.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `point_of_sale`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`admin`@`%` PROCEDURE `populate` (`in_db` VARCHAR(50), `in_table` VARCHAR(50), `in_rows` INT, `in_debug` CHAR(1))  BEGIN


DECLARE col_name VARCHAR(100);
DECLARE col_type VARCHAR(100);
DECLARE col_datatype VARCHAR(100);
DECLARE col_maxlen VARCHAR(100);
DECLARE col_extra VARCHAR(100);
DECLARE col_num_precision VARCHAR(100);
DECLARE col_num_scale VARCHAR(100);
DECLARE func_query VARCHAR(1000);
DECLARE i INT;
DECLARE batch_size INT;

DECLARE done INT DEFAULT 0;
DECLARE cur_datatype cursor FOR
 SELECT column_name,COLUMN_TYPE,data_type,CHARACTER_MAXIMUM_LENGTH,EXTRA,NUMERIC_PRECISION,NUMERIC_SCALE FROM information_schema.columns WHERE table_name=in_table AND table_schema=in_db;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


SET func_query='';
OPEN cur_datatype;
datatype_loop: loop

FETCH cur_datatype INTO col_name, col_type, col_datatype, col_maxlen, col_extra, col_num_precision, col_num_scale;

  IF (done = 1) THEN
    leave datatype_loop;
  END IF;

CASE
WHEN col_extra='auto_increment' THEN SET func_query=concat(func_query,'NULL, ');
WHEN col_datatype in ('double','int','bigint') THEN SET func_query=concat(func_query,'get_int(), ');
WHEN col_datatype in ('varchar','char') THEN SET func_query=concat(func_query,'get_string(',ifnull(col_maxlen,0),'), ');
WHEN col_datatype in ('tinyint', 'smallint','year') or col_datatype='mediumint' THEN SET func_query=concat(func_query,'get_tinyint(), ');
WHEN col_datatype in ('datetime','timestamp') THEN SET func_query=concat(func_query,'get_datetime(), ');
WHEN col_datatype in ('date') THEN SET func_query=concat(func_query,'get_date(), ');
WHEN col_datatype in ('float', 'decimal') THEN SET func_query=concat(func_query,'get_float(',col_num_precision,',',col_num_scale,'), ');
WHEN col_datatype in ('enum','set') THEN SET func_query=concat(func_query,'get_enum("',col_type,'"), ');
WHEN col_datatype in ('GEOMETRY','POINT','LINESTRING','POLYGON','MULTIPOINT','MULTILINESTRING','MULTIPOLYGON','GEOMETRYCOLLECTION') THEN SET func_query=concat(func_query,'NULL, ');
ELSE SET func_query=concat(func_query,'get_varchar(',ifnull(col_maxlen,0),'), ');
END CASE;


end loop  datatype_loop;
close cur_datatype;

SET func_query=trim(trailing ', ' FROM func_query);
SET @func_query=concat("INSERT INTO ", in_db,".",in_table," VALUES (",func_query,");");
SET @func_query=concat("INSERT IGNORE  INTO ", in_db,".",in_table," VALUES (",func_query,")");

SET batch_size = 500;
while batch_size > 0 DO
   set batch_size  = batch_size - 1;
   set @func_query = CONCAT( @func_query , " ,(",func_query,")" );
END WHILE;
set @func_query = CONCAT( @func_query , ";" );
        IF in_debug='Y' THEN
                select @func_query;
        END IF;
SET i=in_rows;
SET batch_size=500;
populate :loop
        WHILE (i>batch_size) DO
          PREPARE t_stmt FROM @func_query;
          EXECUTE t_stmt;
          SET i = i - batch_size;
        END WHILE;
SET @func_query=concat("INSERT INTO ", in_db,".",in_table," VALUES (",func_query,");");
        WHILE (i>0) DO
          PREPARE t_stmt FROM @func_query;
          EXECUTE t_stmt;
          SET i = i - 1;
        END WHILE;
LEAVE populate;
END LOOP populate;
SELECT "Kedar Vaijanapurkar" AS "Developed by";
END$$

CREATE DEFINER=`admin`@`%` PROCEDURE `populate_fk` (`in_db` VARCHAR(50), `in_table` VARCHAR(50), `in_rows` INT, `in_debug` CHAR(1))  fk_load:BEGIN

select CONCAT("UPDATE ",TABLE_NAME," SET ",COLUMN_NAME,"=(SELECT ",REFERENCED_COLUMN_NAME," FROM ",REFERENCED_TABLE_SCHEMA,".",REFERENCED_TABLE_NAME," ORDER BY RAND() LIMIT 1);") into @query from information_schema.key_column_usage where TABLE_NAME=in_table AND TABLE_SCHEMA=in_db AND CONSTRAINT_NAME <> 'PRIMARY';
	IF in_debug='Y' THEN
		select @query;
	END IF;
if @query is null then
select "No referential information found." as Error;
LEAVE fk_load;
end if;

set  foreign_key_checks=0;
call populate(in_db,in_table,in_rows,'N');
PREPARE t_stmt FROM @query;
EXECUTE t_stmt;

set  foreign_key_checks=1;

END$$

--
-- Functions
--
CREATE DEFINER=`admin`@`%` FUNCTION `get_date` () RETURNS VARCHAR(10) CHARSET utf8mb4 RETURN DATE(FROM_UNIXTIME(RAND() * (1356892200 - 1325356200) + 1325356200))$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_datetime` () RETURNS VARCHAR(30) CHARSET utf8mb4 RETURN FROM_UNIXTIME(ROUND(RAND() * (1356892200 - 1325356200)) + 1325356200)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_enum` (`col_type` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 RETURN if((@var:=ceil(rand()*10)) > (length(col_type)-length(replace(col_type,',',''))+1),(length(col_type)-length(replace(col_type,',',''))+1),@var)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_float` (`in_precision` INT, `in_scale` INT) RETURNS VARCHAR(100) CHARSET utf8mb4 RETURN round(rand()*pow(10,(in_precision-in_scale)),in_scale)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_int` () RETURNS INT(11) RETURN floor(rand()*10000000)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_string` (`in_strlen` INT) RETURNS VARCHAR(500) CHARSET utf8mb4 BEGIN
set @var:='';
IF (in_strlen>500) THEN SET in_strlen=500; END IF;
while(in_strlen>0) do
set @var:=concat(@var,IFNULL(ELT(1+FLOOR(RAND() * 53), 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',' ','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'),'Kedar'));
set in_strlen:=in_strlen-1;
end while;
RETURN @var;
END$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_time` () RETURNS INT(11) RETURN TIME(FROM_UNIXTIME(RAND() * (1356892200 - 1325356200) + 1325356200))$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_tinyint` () RETURNS INT(11) RETURN floor(rand()*100)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_varchar` (`in_length` VARCHAR(500)) RETURNS VARCHAR(500) CHARSET utf8mb4 RETURN SUBSTRING(MD5(RAND()) FROM 1 FOR in_length)$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Customer`
--

CREATE TABLE `Customer` (
  `id` int(11) NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact` int(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Invoice`
--

CREATE TABLE `Invoice` (
  `id` int(11) NOT NULL,
  `total_amount` int(11) UNSIGNED DEFAULT 0,
  `amount_tendered` int(11) UNSIGNED DEFAULT 0,
  `date_recorded` date NOT NULL DEFAULT current_timestamp(),
  `user_id` int(11) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Product`
--

CREATE TABLE `Product` (
  `id` int(11) NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `expired_date` date DEFAULT NULL,
  `unit_in_stock` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `disc_percentage` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `distributor_price` int(255) DEFAULT NULL,
  `re_order_level` varchar(255) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Product Category`
--

CREATE TABLE `Product Category` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '-'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Product Unit`
--

CREATE TABLE `Product Unit` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '-'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Purchase Order`
--

CREATE TABLE `Purchase Order` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL,
  `sub_total` int(11) UNSIGNED NOT NULL,
  `order_date` date NOT NULL DEFAULT current_timestamp(),
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `product_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Receive Product`
--

CREATE TABLE `Receive Product` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL,
  `unit_price` int(11) UNSIGNED NOT NULL,
  `sub_total` int(11) UNSIGNED NOT NULL,
  `received_date` date NOT NULL DEFAULT current_timestamp(),
  `product_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Revoked Tokens`
--

CREATE TABLE `Revoked Tokens` (
  `id` int(11) NOT NULL,
  `token` text DEFAULT NULL,
  `signed_out` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Sales`
--

CREATE TABLE `Sales` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `sub_total` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `invoice_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `Supplier`
--

CREATE TABLE `Supplier` (
  `id` int(11) NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `fullname` varchar(255) DEFAULT NULL,
  `role` varchar(255) NOT NULL,
  `contact` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Customer`
--
ALTER TABLE `Customer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Invoice`
--
ALTER TABLE `Invoice`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `Product`
--
ALTER TABLE `Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category` (`category_id`),
  ADD KEY `user` (`user_id`),
  ADD KEY `unit` (`unit_id`);

--
-- Indexes for table `Product Category`
--
ALTER TABLE `Product Category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Product Unit`
--
ALTER TABLE `Product Unit`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `Receive Product`
--
ALTER TABLE `Receive Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `Revoked Tokens`
--
ALTER TABLE `Revoked Tokens`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Sales`
--
ALTER TABLE `Sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_id` (`invoice_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `Supplier`
--
ALTER TABLE `Supplier`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Customer`
--
ALTER TABLE `Customer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Invoice`
--
ALTER TABLE `Invoice`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Product`
--
ALTER TABLE `Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Product Category`
--
ALTER TABLE `Product Category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Product Unit`
--
ALTER TABLE `Product Unit`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Receive Product`
--
ALTER TABLE `Receive Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Revoked Tokens`
--
ALTER TABLE `Revoked Tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Sales`
--
ALTER TABLE `Sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Supplier`
--
ALTER TABLE `Supplier`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `User`
--
ALTER TABLE `User`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Invoice`
--
ALTER TABLE `Invoice`
  ADD CONSTRAINT `Invoice_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Product`
--
ALTER TABLE `Product`
  ADD CONSTRAINT `category` FOREIGN KEY (`category_id`) REFERENCES `Product Category` (`id`),
  ADD CONSTRAINT `unit` FOREIGN KEY (`unit_id`) REFERENCES `Product Unit` (`id`),
  ADD CONSTRAINT `user` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  ADD CONSTRAINT `Purchase Order_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`),
  ADD CONSTRAINT `Purchase Order_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `Supplier` (`id`),
  ADD CONSTRAINT `Purchase Order_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Receive Product`
--
ALTER TABLE `Receive Product`
  ADD CONSTRAINT `Receive Product_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`),
  ADD CONSTRAINT `Receive Product_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `Supplier` (`id`),
  ADD CONSTRAINT `Receive Product_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Sales`
--
ALTER TABLE `Sales`
  ADD CONSTRAINT `Sales_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `Invoice` (`id`),
  ADD CONSTRAINT `Sales_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
